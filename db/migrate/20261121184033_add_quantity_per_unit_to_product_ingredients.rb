class AddQuantityPerUnitToProductIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :product_ingredients, :quantity_per_unit, :decimal, precision: 10, scale: 3, default: 0, null: false
  end
end
