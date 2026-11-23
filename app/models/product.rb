class Product < ApplicationRecord
  KINDS = %w[bebida comida postre].freeze

  SUBKINDS = {
    "bebida" => %w[cafe_negro cafe_con_leche frios chai otro],
    "comida" => %w[otro],
    "postre" => %w[otro]
  }.freeze

  SUBKIND_LABELS = {
    "cafe_negro"     => "Café negro",
    "cafe_con_leche" => "Café con leche",
    "frios"          => "Fríos",
    "chai"           => "Chai",
    "otro"           => "Otro"
  }.freeze

  has_one_attached :photo

  has_many :product_ingredients, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :product
  has_many :ingredients, through: :product_ingredients
  has_many :option_groups, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :product

  attr_accessor :ingredients_list

  after_save :sync_ingredients_list, if: -> { @ingredients_list_assigned }

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :bebidas,  -> { where(kind: "bebida").order(:name) }
  scope :comidas,  -> { where(kind: "comida").order(:name) }
  scope :postres,  -> { where(kind: "postre").order(:name) }
  scope :featured, -> { where(featured: true).order(:name) }

  def subkind_label
    SUBKIND_LABELS[subkind] || "Otro"
  end

  def margin
    price.to_d - cost.to_d
  end

  def food?
    kind == "comida"
  end

  def drink?
    kind == "bebida"
  end

  def dessert?
    kind == "postre"
  end

  def customizable?
    product_ingredients.any? || option_groups.any?
  end

  def ingredients_list=(value)
    @ingredients_list_assigned = true
    @ingredients_list = value.to_s
  end

  def ingredients_list
    return @ingredients_list if @ingredients_list
    product_ingredients.includes(:ingredient).defaults.map { |pi| pi.ingredient.name }.join("\n")
  end

  def suggested_extra_price
    base = (price.to_d * BigDecimal("0.10"))
    rounded = (base / 5).ceil * 5
    [rounded, BigDecimal("5")].max
  end

  private

  def sync_ingredients_list
    names = @ingredients_list.to_s.split(/[\n,]+/).map { |s| s.strip }.reject(&:blank?).uniq { |s| s.downcase }
    desired = names.map { |n| Ingredient.find_by("LOWER(name) = ?", n.downcase) || Ingredient.create!(name: n) }

    current_defaults = product_ingredients.where(default_included: true).includes(:ingredient).to_a
    keep_ids = desired.map(&:id)

    current_defaults.each do |pi|
      pi.destroy unless keep_ids.include?(pi.ingredient_id)
    end

    existing_ids = current_defaults.map(&:ingredient_id)
    desired.each_with_index do |ing, idx|
      next if existing_ids.include?(ing.id)
      product_ingredients.create!(
        ingredient: ing,
        default_included: true,
        extra_price: suggested_extra_price,
        position: idx
      )
    end
  end
end
