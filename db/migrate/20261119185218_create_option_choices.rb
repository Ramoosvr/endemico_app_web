class CreateOptionChoices < ActiveRecord::Migration[8.1]
  def change
    create_table :option_choices do |t|
      t.references :option_group, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :extra_price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :default_selected, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
