# Inventory driven by the "Matriz" Google Sheet:
# - ingredients get the Sheet's section, brand and package data, and can be
#   archived (old POS ingredients are archived, never deleted).
# - recipe_lines: what each product consumes, per size. A line with a `slot`
#   (e.g. "Leche", "Sabor") uses the ingredient of the option chosen in that
#   group, falling back to the line's own ingredient.
# - inventory_movements: one row per stock change (sale, refund, merma,
#   purchase, adjustment) so every number can be traced.
class CreateMatrizInventory < ActiveRecord::Migration[8.1]
  def change
    change_table :ingredients, bulk: true do |t|
      t.string   :section
      t.integer  :section_position, default: 0, null: false
      t.integer  :position, default: 0, null: false
      t.string   :brand
      t.decimal  :package_size,  precision: 12, scale: 3
      t.string   :package_unit
      t.decimal  :package_count, precision: 12, scale: 3
      t.decimal  :package_price, precision: 10, scale: 2
      t.datetime :archived_at
    end

    add_column :option_choices, :ingredient_id, :integer
    add_index  :option_choices, :ingredient_id

    create_table :recipe_lines do |t|
      t.references :product, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.string  :size
      t.string  :slot
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    create_table :inventory_movements do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.integer :order_id
      t.integer :order_item_id
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string  :kind, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :stock_after, precision: 12, scale: 3
      t.string  :note
      t.timestamps
    end
    add_index :inventory_movements, :order_id
    add_index :inventory_movements, :order_item_id
    add_index :inventory_movements, [ :kind, :created_at ]

    add_column :order_items, :inventory_status, :string
    add_column :orders, :refund_prepared, :boolean
  end
end
