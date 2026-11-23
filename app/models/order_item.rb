class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_many :removed_ingredients, class_name: "OrderItemRemovedIngredient", dependent: :destroy, inverse_of: :order_item
  has_many :extras, class_name: "OrderItemExtra", dependent: :destroy, inverse_of: :order_item
  has_many :chosen_options, class_name: "OrderItemOptionChoice", dependent: :destroy, inverse_of: :order_item

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  def recalc_line_total!
    extras_sum  = extras.sum(:extra_price)
    options_sum = chosen_options.sum(:extra_price)
    mods = extras_sum + options_sum
    total = (unit_price.to_d + mods.to_d) * quantity.to_i
    update!(modifiers_price: mods, line_total: total)
  end

  def modifier_lines
    lines = []
    removed_ingredients.each { |r| lines << "sin #{r.ingredient_name}" }
    extras.each               { |e| lines << "+ #{e.ingredient_name}" }
    chosen_options.each       { |c| lines << "#{c.option_group_name}: #{c.choice_name}" }
    lines
  end
end
