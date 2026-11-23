class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "open"
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    add_index :orders, :status
  end
end
