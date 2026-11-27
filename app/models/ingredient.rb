class Ingredient < ApplicationRecord
  UNITS = %w[pza g kg ml l].freeze

  CATEGORIES = %w[
    vasos
    tapas_mangas
    leches
    cafe_polvos
    comida
    salsas_cremas
    congelados
    extras
    otros
  ].freeze

  # Cups, lids and sleeves: consumed from stock but not shown to the barista
  # in the "Incluye" list of the order pop-up.
  PACKAGING_CATEGORIES = %w[vasos tapas_mangas].freeze

  CATEGORY_LABELS = {
    "vasos"         => "Vasos",
    "tapas_mangas"  => "Tapas y mangas",
    "leches"        => "Leches",
    "cafe_polvos"   => "Café y polvos",
    "comida"        => "Comida",
    "salsas_cremas" => "Salsas y cremas",
    "congelados"    => "Congelados",
    "extras"        => "Endulzantes y desechables",
    "otros"         => "Otros"
  }.freeze

  normalizes :name, with: ->(n) { n.to_s.strip }

  has_many :product_ingredients, dependent: :destroy
  has_many :products, through: :product_ingredients
  has_many :option_choice_ingredients, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :unit, presence: true, inclusion: { in: UNITS }
  validates :category, inclusion: { in: CATEGORIES }
  validates :stock, :min_stock, :cost_per_unit,
            numericality: { greater_than_or_equal_to: 0 }

  scope :ordered,      -> { order(Arel.sql("LOWER(name)")) }
  scope :below_min,    -> { where("stock < min_stock") }

  def category_label
    CATEGORY_LABELS[category] || "Otros"
  end

  def stock_ratio
    return 1.0 if min_stock.to_d.zero?
    (stock.to_d / min_stock.to_d).to_f
  end

  def below_min?
    stock.to_d < min_stock.to_d
  end
end
