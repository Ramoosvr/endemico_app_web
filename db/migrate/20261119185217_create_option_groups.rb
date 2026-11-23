class CreateOptionGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :option_groups do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :required, null: false, default: true
      t.string :selection_mode, null: false, default: "single"
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
