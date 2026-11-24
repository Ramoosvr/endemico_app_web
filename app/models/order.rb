class Order < ApplicationRecord
  STATUSES = %w[open completed cancelled].freeze
  PAYMENT_METHODS = %w[efectivo tarjeta transferencia dolares cortesía].freeze

  belongs_to :user
  has_many :order_items, -> { order(:id) }, dependent: :destroy, inverse_of: :order

  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true

  scope :open,      -> { where(status: "open") }
  scope :completed, -> { where(status: "completed") }

  def recalc_total!
    update!(total: order_items.sum(:line_total))
  end

  def complete!(payment_method: nil, usd_received: nil, usd_rate: nil, cash_received: nil)
    transaction do
      order_items.includes(
        :removed_ingredients,
        :extras,
        chosen_options: { option_choice: :option_choice_ingredients },
        product: { product_ingredients: :ingredient }
      ).each do |item|
        product = item.product
        new_stock = product.stock.to_i - item.quantity.to_i
        product.update!(stock: [ new_stock, 0 ].max)

        decrement_ingredients_for(item)
      end
      attrs = { status: "completed", completed_at: Time.current }
      attrs[:payment_method] = payment_method if payment_method.present?
      attrs[:usd_received]   = usd_received   if usd_received.present?
      attrs[:usd_rate]       = usd_rate       if usd_rate.present?
      attrs[:cash_received]  = cash_received  if cash_received.present?
      update!(attrs)
    end
  end

  def usd_change_mxn
    return nil unless usd_received.to_f.positive? && usd_rate.to_f.positive?
    (usd_received.to_d * usd_rate.to_d) - total.to_d
  end

  private

  def decrement_ingredients_for(item)
    qty = item.quantity.to_i
    return if qty <= 0

    removed_ids = item.removed_ingredients.map(&:ingredient_id).to_set
    extra_ids   = item.extras.map(&:ingredient_id).to_set

    consumed = Hash.new { |h, k| h[k] = 0.to_d }

    item.product.product_ingredients.each do |pi|
      next if pi.quantity_per_unit.to_d.zero?

      if pi.default_included?
        next if removed_ids.include?(pi.ingredient_id)
        consumed[pi.ingredient_id] += pi.quantity_per_unit.to_d * qty
      elsif extra_ids.include?(pi.ingredient_id)
        consumed[pi.ingredient_id] += pi.quantity_per_unit.to_d * qty
      end
    end

    item.chosen_options.each do |cop|
      cop.option_choice.option_choice_ingredients.each do |oci|
        next if oci.quantity_per_unit.to_d.zero?
        consumed[oci.ingredient_id] += oci.quantity_per_unit.to_d * qty
      end
    end

    consumed.each do |ingredient_id, amount|
      ing = Ingredient.find(ingredient_id)
      new_stock = [ ing.stock.to_d - amount, 0.to_d ].max
      ing.update!(stock: new_stock)
    end
  end
end
