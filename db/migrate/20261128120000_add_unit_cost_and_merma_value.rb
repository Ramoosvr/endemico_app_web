class AddUnitCostAndMermaValue < ActiveRecord::Migration[8.1]
  # Additive only. unit_cost keeps the Matriz "PRECIO UNITARIO" with all its
  # decimals (cost_per_unit only keeps 2, so milk at $0.0238/ml became $0.02).
  # mermas.value freezes what the merma cost on the day it was recorded.
  def change
    add_column :ingredients, :unit_cost, :decimal, precision: 16, scale: 6
    add_column :mermas, :value, :decimal, precision: 12, scale: 2
  end
end
