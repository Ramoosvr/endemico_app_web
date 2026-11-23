class AddStockFieldsToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :unit,          :string,  default: "pza", null: false
    add_column :ingredients, :stock,         :decimal, precision: 12, scale: 3, default: 0, null: false
    add_column :ingredients, :min_stock,     :decimal, precision: 12, scale: 3, default: 0, null: false
    add_column :ingredients, :cost_per_unit, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_column :ingredients, :supplier,      :string
  end
end
