class CreateOrderItemRemovedIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :order_item_removed_ingredients do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.string :ingredient_name, null: false

      t.timestamps
    end

    add_index :order_item_removed_ingredients,
              [ :order_item_id, :ingredient_id ],
              unique: true,
              name: "index_oi_removed_on_item_and_ingredient"
  end
end
