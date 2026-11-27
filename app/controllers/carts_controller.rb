class CartsController < ApplicationController
  before_action :set_order

  def show
    redirect_to main_path
  end

  def set_name
    name = params[:customer_name].to_s.strip.presence
    @order.update(customer_name: name)
    redirect_to main_path
  end

  def add_item
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1

    remove_ids = Array(params[:remove_ingredient_ids]).map(&:to_i).reject(&:zero?)
    extra_pi_ids = Array(params[:extra_product_ingredient_ids]).map(&:to_i).reject(&:zero?)
    choice_ids = Array(params[:option_choice_ids]).map(&:to_i).reject(&:zero?)
    notes = params[:notes].to_s.strip.presence

    extras      = product.product_ingredients.where(id: extra_pi_ids)
    removables  = product.product_ingredients.defaults.where(ingredient_id: remove_ids)
    choices     = OptionChoice.joins(option_group: :product)
                              .where(products: { id: product.id }, id: choice_ids)
                              .where(option_groups: { active: true }, active: true, available: true)
                              .where.not(option_groups: { selection_mode: "counter" })
    counters    = counter_choices_for(product)
    if counters.nil?
      redirect_back fallback_location: main_path, alert: "Elige el sabor del extra antes de agregarlo."
      return
    end

    OrderItem.transaction do
      item = @order.order_items.create!(
        product: product,
        quantity: quantity,
        unit_price: product.price,
        modifiers_price: 0,
        line_total: product.price * quantity,
        notes: notes
      )

      removables.each do |pi|
        item.removed_ingredients.create!(
          ingredient_id: pi.ingredient_id,
          ingredient_name: pi.ingredient.name
        )
      end

      extras.each do |pi|
        item.extras.create!(
          ingredient_id: pi.ingredient_id,
          ingredient_name: pi.ingredient.name,
          extra_price: pi.extra_price
        )
      end

      choices.includes(:option_group).each do |oc|
        item.chosen_options.create!(
          option_choice_id: oc.id,
          option_group_name: oc.option_group.name,
          choice_name: oc.name,
          extra_price: oc.extra_price
        )
      end

      counters.each do |oc, count|
        item.chosen_options.create!(
          option_choice_id: oc.id,
          option_group_name: oc.option_group.name,
          choice_name: oc.name,
          extra_price: oc.extra_price,
          quantity: count
        )
      end

      item.recalc_line_total!
      @order.recalc_total!
    end

    redirect_to main_path, notice: "#{product.name} agregado."
  end

  def update_item
    item = @order.order_items.find(params[:id])
    qty = params[:quantity].to_i
    if qty <= 0
      item.destroy
    else
      item.update!(quantity: qty)
      item.recalc_line_total!
    end
    @order.recalc_total!
    redirect_to main_path
  end

  def remove_item
    item = @order.order_items.find(params[:id])
    item.destroy
    @order.recalc_total!
    redirect_to main_path, notice: "Artículo quitado."
  end

  def checkout
    if @order.order_items.empty?
      redirect_to main_path, alert: "El carrito está vacío."
      return
    end

    method = params[:payment_method].to_s
    method = nil unless Order::PAYMENT_METHODS.include?(method)

    extra = {}
    if method == "efectivo" && params[:cash_received].present?
      cash = params[:cash_received].to_s.gsub(",", ".").to_d rescue 0.to_d
      if cash < @order.total.to_d
        redirect_to pedido_path, alert: "Faltan $#{format('%.2f', (@order.total.to_d - cash))}: te dieron $#{format('%.2f', cash)} y el total es $#{format('%.2f', @order.total)}."
        return
      end
      extra = { cash_received: cash }
    end

    if method == "dolares"
      usd_received = params[:usd_received].to_s.gsub(",", ".").to_d rescue 0.to_d
      usd_rate     = (params[:usd_rate].presence&.to_s&.gsub(",", ".")&.to_d rescue nil) ||
                     (Setting.get(:usd_rate) || 18.to_d)
      if usd_received <= 0 || usd_rate <= 0
        redirect_to pedido_path, alert: "Monto en dólares inválido."
        return
      end
      mxn_equiv = usd_received * usd_rate
      if mxn_equiv < @order.total.to_d
        redirect_to pedido_path, alert: "Faltan dólares: equivalen a $#{format('%.2f', mxn_equiv)} y el total es $#{format('%.2f', @order.total)}."
        return
      end
      extra = { usd_received: usd_received, usd_rate: usd_rate }
    end

    @order.complete!(payment_method: method, **extra)

    notice = "Pedido cobrado: $#{format("%.2f", @order.total)}#{method ? " (#{method})" : ""}."
    if method == "dolares" && @order.usd_change_mxn
      notice += " Cambio: $#{format('%.2f', @order.usd_change_mxn)} MXN."
    end
    if method == "efectivo" && @order.cash_received
      change = @order.cash_received.to_d - @order.total.to_d
      if change > 0
        notice += " Recibiste $#{format('%.2f', @order.cash_received)} · Cambio: $#{format('%.2f', change)}."
      end
    end
    redirect_to main_path, notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to main_path, alert: "No se pudo cobrar: #{e.message}"
  end

  private

  MAX_COUNTER = 10

  # Counter groups arrive as counter_qty[group_id] = n and, when the group has
  # several choices (e.g. pump flavors), counter_choice[group_id] = choice id.
  # Returns [[choice, n], ...], or nil when a flavor is missing.
  def counter_choices_for(product)
    qtys = params.fetch(:counter_qty, {}).to_unsafe_h
    picks = params.fetch(:counter_choice, {}).to_unsafe_h
    groups = product.option_groups.where(selection_mode: "counter").includes(:option_choices)

    groups.filter_map do |og|
      count = qtys[og.id.to_s].to_i.clamp(0, MAX_COUNTER)
      next if count.zero?

      choices = og.option_choices.select(&:available)
      return nil if choices.empty?

      choice =
        if og.option_choices.size == 1
          choices.first
        else
          choices.find { |c| c.id == picks[og.id.to_s].to_i }
        end
      return nil if choice.nil?

      [ choice, count ]
    end
  end

  def set_order
    @order = current_order
  end
end
