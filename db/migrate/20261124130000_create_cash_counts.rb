class CreateCashCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_counts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :d1,   default: 0, null: false
      t.integer :d2,   default: 0, null: false
      t.integer :d5,   default: 0, null: false
      t.integer :d10,  default: 0, null: false
      t.integer :d20,  default: 0, null: false
      t.integer :d50,  default: 0, null: false
      t.integer :d100, default: 0, null: false
      t.integer :d200, default: 0, null: false
      t.integer :d500, default: 0, null: false
      t.decimal :total, precision: 10, scale: 2, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :cash_counts, [ :kind, :created_at ]
  end
end
