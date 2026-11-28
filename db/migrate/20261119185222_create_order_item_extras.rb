class CreateOrderItemExtras < ActiveRecord::Migration[8.1]
  def change
    create_table :order_item_extras do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.string :ingredient_name, null: false
      t.decimal :extra_price, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :order_item_extras,
              [ :order_item_id, :ingredient_id ],
              unique: true,
              name: "index_oi_extras_on_item_and_ingredient"
  end
end
