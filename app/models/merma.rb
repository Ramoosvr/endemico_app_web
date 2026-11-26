class Merma < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }

  after_create :decrement_ingredient_stock

  private

  def decrement_ingredient_stock
    new_stock = [ ingredient.stock.to_d - amount.to_d, 0.to_d ].max
    ingredient.update!(stock: new_stock)
  end
end
