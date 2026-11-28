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

  # Created in the POS: gets a code so the Matriz sheet can pick it up.
  after_create :assign_pos_code, if: -> { external_id.blank? }
  # A cost typed by hand in the POS replaces the precise Matriz one.
  before_save -> { self.unit_cost = cost_per_unit }, if: -> { cost_per_unit_changed? && !unit_cost_changed? }

  normalizes :name, with: ->(n) { n.to_s.strip }

  has_many :product_ingredients, dependent: :destroy
  has_many :products, through: :product_ingredients
  has_many :option_choice_ingredients, dependent: :destroy
  has_many :recipe_lines, dependent: :restrict_with_error
  has_many :inventory_movements, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :unit, presence: true, inclusion: { in: UNITS }
  validates :category, inclusion: { in: CATEGORIES }
  # Stock may go below zero: a sale is never blocked, and a negative number
  # shows that the last count or a recipe needs checking.
  validates :stock, numericality: true
  validates :min_stock, :cost_per_unit,
            numericality: { greater_than_or_equal_to: 0 }

  scope :active,       -> { where(archived_at: nil) }
  scope :archived,     -> { where.not(archived_at: nil) }
  scope :ordered,      -> { active.order(Arel.sql("LOWER(name)")) }
  scope :by_section,   -> { active.order(:section_position, :position, Arel.sql("LOWER(name)")) }
  scope :below_min,    -> { active.where("stock < min_stock") }

  # Cost of one unit (1 ml, 1 g, 1 pza). Prefers the precise Matriz value.
  def effective_unit_cost
    (unit_cost.presence || cost_per_unit).to_d
  end

  def category_label
    CATEGORY_LABELS[category] || "Otros"
  end

  # Section from the Matriz sheet ("LECHES Y LÁCTEOS"), or the old category.
  def section_label
    section.presence || category_label
  end

  def assign_pos_code
    update_columns(external_id: "POS-#{id}")
  end

  def archived?
    archived_at.present?
  end

  # Changes the stock by `delta` (negative = goes out) and records why.
  # Locks the row so two sales at once cannot overwrite each other.
  def apply_movement!(delta, kind:, order: nil, order_item: nil, user: nil, note: nil)
    with_lock do
      new_stock = stock.to_d + delta.to_d
      update_columns(stock: new_stock, updated_at: Time.current)
      inventory_movements.create!(
        kind: kind, quantity: delta, stock_after: new_stock,
        order: order, order_item: order_item, user: user, note: note
      )
    end
  end

  def stock_ratio
    return 1.0 if min_stock.to_d.zero?
    (stock.to_d / min_stock.to_d).to_f
  end

  def below_min?
    stock.to_d < min_stock.to_d
  end
end
