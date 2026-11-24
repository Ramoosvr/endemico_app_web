class OptionChoiceIngredient < ApplicationRecord
  belongs_to :option_choice
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :option_choice_id }
  validates :quantity_per_unit, numericality: { greater_than_or_equal_to: 0 }
end
