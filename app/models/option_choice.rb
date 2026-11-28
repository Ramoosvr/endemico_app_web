class OptionChoice < ApplicationRecord
  belongs_to :option_group
  # The ingredient this choice stands for in a recipe slot
  # (Leche: Avena -> "Leche de avena"; Sabor: Especias -> "Chai Especias").
  belongs_to :ingredient, optional: true

  has_many :option_choice_ingredients, dependent: :destroy, inverse_of: :option_choice
  has_many :ingredients, through: :option_choice_ingredients

  validates :name, presence: true
  validates :extra_price, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
