class OptionChoice < ApplicationRecord
  belongs_to :option_group

  has_many :option_choice_ingredients, dependent: :destroy, inverse_of: :option_choice
  has_many :ingredients, through: :option_choice_ingredients

  validates :name, presence: true
  validates :extra_price, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
