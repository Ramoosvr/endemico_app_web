class Merma < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }

  # Set when the stock was already taken out (a refunded drink that had been
  # prepared): the merma is recorded for reports but stock is not touched again.
  attr_accessor :skip_stock

  after_create :decrement_ingredient_stock, unless: :skip_stock

  private

  def decrement_ingredient_stock
    ingredient.apply_movement!(-amount.to_d, kind: "merma", user: user, note: reason)
  end
end
