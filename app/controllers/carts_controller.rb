class CartsController < ApplicationController
  before_action :set_order

  def show
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
    choices     = OptionChoice.joins(option_group: :product).where(products: { id: product.id }, id: choice_ids)

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

    @order.complete!(payment_method: method)

    method_label = method ? " (#{method})" : ""
    redirect_to main_path, notice: "Pedido cobrado: $#{format("%.2f", @order.total)}#{method_label}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to main_path, alert: "No se pudo cobrar: #{e.message}"
  end

  private

  def set_order
    @order = current_order
  end
end
