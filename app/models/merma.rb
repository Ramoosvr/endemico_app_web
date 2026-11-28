class Merma < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }

  # Set when the stock was already taken out (a refunded drink that had been
  # prepared): the merma is recorded for reports but stock is not touched again.
  attr_accessor :skip_stock

  before_create -> { self.value ||= (amount.to_d * ingredient.effective_unit_cost).round(2) }
  after_create :decrement_ingredient_stock, unless: :skip_stock

  scope :from_refunds, -> { where("reason LIKE 'Devolución pedido #%'") }

  # Value frozen when recorded; older mermas fall back to today's cost.
  def cost
    value || (amount.to_d * ingredient.effective_unit_cost).round(2)
  end

  def from_refund?
    reason.to_s.start_with?("Devolución pedido #")
  end

  private

  def decrement_ingredient_stock
    ingredient.apply_movement!(-amount.to_d, kind: "merma", user: user, note: reason)
  end
end
