class Order < ApplicationRecord
  STATUSES = %w[open completed cancelled refunded].freeze
  PAYMENT_METHODS = %w[efectivo tarjeta transferencia dolares cortesía].freeze

  belongs_to :user
  belongs_to :refunded_by_user, class_name: "User", optional: true
  has_many :order_items, -> { order(:id) }, dependent: :destroy, inverse_of: :order

  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true

  scope :open,      -> { where(status: "open") }
  scope :completed, -> { where(status: "completed") }
  scope :refunded,  -> { where(status: "refunded") }
  scope :pending_preparation, -> { where(status: "completed", prepared_at: nil) }
  scope :prepared,            -> { where.not(prepared_at: nil) }

  def recalc_total!
    update!(total: order_items.sum(:line_total))
  end

  def complete!(payment_method: nil, usd_received: nil, usd_rate: nil, cash_received: nil)
    transaction do
      order_items.includes(
        :removed_ingredients,
        :extras,
        chosen_options: { option_choice: [ :ingredient, { option_choice_ingredients: :ingredient } ] },
        product: [ { product_ingredients: :ingredient }, { recipe_lines: :ingredient } ]
      ).each do |item|
        product = item.product
        new_stock = product.stock.to_i - item.quantity.to_i
        product.update!(stock: [ new_stock, 0 ].max)

        consume_ingredients_for(item)
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

  # prepared: true  -> the drinks were already made: what they used goes to
  #                   merma and does not come back to stock.
  # prepared: false -> nothing was made: every ingredient goes back to stock.
  # Orders sold before recipes existed have no movements, so stock is untouched.
  def refund!(reason:, user:, prepared: false)
    raise ArgumentError, "Solo se pueden devolver pedidos completados" unless status == "completed"

    transaction do
      order_items.includes(:product).each do |item|
        product = item.product
        product.update!(stock: product.stock.to_i + item.quantity.to_i) unless prepared
      end

      note = "Devolución pedido ##{id}#{reason.present? ? ": #{reason.to_s.strip}" : ""}"
      sales = InventoryMovement.where(order_id: id, kind: "venta").includes(:ingredient)
      sales.group_by(&:ingredient).each do |ingredient, movements|
        used = movements.sum { |m| -m.quantity.to_d }
        next unless used.positive?

        if prepared
          Merma.create!(ingredient: ingredient, user: user, amount: used, reason: note, skip_stock: true)
          ingredient.inventory_movements.create!(kind: "devolucion_merma", quantity: 0, stock_after: ingredient.stock,
                                                 order: self, user: user, note: "#{used} #{ingredient.unit} a merma")
        else
          ingredient.apply_movement!(used, kind: "devolucion", order: self, user: user, note: note)
        end
      end

      update!(
        status: "refunded",
        refunded_at: Time.current,
        refund_reason: reason.to_s.strip.presence,
        refunded_by_user: user,
        refund_prepared: prepared
      )
    end
  end

  private

  # Never blocks the sale: if anything goes wrong the item is marked "error"
  # and the order still completes.
  def consume_ingredients_for(item)
    result = Inventory::Deduction.for(item)
    transaction(requires_new: true) do
      result.amounts.each do |ingredient, amount|
        next unless amount.positive?
        ingredient.apply_movement!(-amount, kind: "venta", order: self, order_item: item, user: user)
      end
    end
    item.update_column(:inventory_status, result.status)
  rescue StandardError => e
    Rails.logger.error("[inventario] pedido #{id} item #{item.id}: #{e.class}: #{e.message}")
    item.update_column(:inventory_status, "error")
  end
end
