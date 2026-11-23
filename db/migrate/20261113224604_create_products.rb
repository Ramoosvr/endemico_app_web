class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.decimal :cost, precision: 10, scale: 2, null: false, default: 0
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :stock, null: false, default: 0

      t.timestamps
    end

    add_index :products, :kind
  end
end
