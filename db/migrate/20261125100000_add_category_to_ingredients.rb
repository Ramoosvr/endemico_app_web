class AddCategoryToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :category, :string, default: "otros", null: false
    add_index :ingredients, :category
  end
end
