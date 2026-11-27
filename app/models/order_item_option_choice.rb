class OrderItemOptionChoice < ApplicationRecord
  belongs_to :order_item
  belongs_to :option_choice

  # "Leche: Avena", "Shot extra de espresso ×2", "Pump de jarabe extra: Vainilla ×2"
  def label
    count = quantity.to_i > 1 ? " ×#{quantity}" : ""
    if option_group_name == choice_name
      "#{choice_name}#{count}"
    else
      "#{option_group_name}: #{choice_name}#{count}"
    end
  end
end
