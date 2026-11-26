class CreateMermas < ActiveRecord::Migration[8.1]
  def change
    create_table :mermas do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 3, null: false
      t.text :reason

      t.timestamps
    end
    add_index :mermas, :created_at
  end
end
