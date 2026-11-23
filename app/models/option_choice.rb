class OptionChoice < ApplicationRecord
  belongs_to :option_group

  validates :name, presence: true
  validates :extra_price, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
