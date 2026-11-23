class CreateProductIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :product_ingredients do |t|
      t.references :product, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.boolean :default_included, null: false, default: true
      t.decimal :extra_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :product_ingredients, [:product_id, :ingredient_id], unique: true
  end
end
