class Ingredient < ApplicationRecord
  UNITS = %w[pza g kg ml l].freeze

  normalizes :name, with: ->(n) { n.to_s.strip }

  has_many :product_ingredients, dependent: :destroy
  has_many :products, through: :product_ingredients

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :unit, presence: true, inclusion: { in: UNITS }
  validates :stock, :min_stock, :cost_per_unit,
            numericality: { greater_than_or_equal_to: 0 }

  scope :ordered,      -> { order(Arel.sql("LOWER(name)")) }
  scope :below_min,    -> { where("stock < min_stock") }

  def stock_ratio
    return 1.0 if min_stock.to_d.zero?
    (stock.to_d / min_stock.to_d).to_f
  end

  def below_min?
    stock.to_d < min_stock.to_d
  end
end
