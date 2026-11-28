# One ingredient a product consumes. `size` limits the line to one size
# ("12 oz", "16 oz"); blank applies to every size. `slot` names an option
# group ("Leche", "Sabor"): the ingredient of the option chosen there replaces
# this line's ingredient (which stays as the fallback).
class RecipeLine < ApplicationRecord
  belongs_to :product
  belongs_to :ingredient

  validates :quantity, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:position, :id) }

  def applies_to_size?(chosen_size)
    size.blank? || chosen_size.to_s.strip.casecmp?(size.to_s.strip)
  end
end
