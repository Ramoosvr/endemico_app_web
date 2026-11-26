class AddExternalIdToCatalog < ActiveRecord::Migration[8.1]
  def change
    add_column :products,       :external_id, :string
    add_column :option_groups,  :external_id, :string
    add_column :option_choices, :external_id, :string
    add_column :ingredients,    :external_id, :string

    add_index :products,       :external_id, unique: true
    add_index :option_groups,  :external_id, unique: true
    add_index :option_choices, :external_id, unique: true
    add_index :ingredients,    :external_id, unique: true
  end
end
