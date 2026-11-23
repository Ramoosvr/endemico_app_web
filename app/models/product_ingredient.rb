class ProductIngredient < ApplicationRecord
  belongs_to :product
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :product_id }
  validates :extra_price, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_per_unit, numericality: { greater_than_or_equal_to: 0 }

  scope :defaults, -> { where(default_included: true) }
  scope :extras,   -> { where(default_included: false) }
  scope :ordered,  -> { order(:position, :id) }
end
