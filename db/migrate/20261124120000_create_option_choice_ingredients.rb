class CreateOptionChoiceIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :option_choice_ingredients do |t|
      t.references :option_choice, null: false, foreign_key: true
      t.references :ingredient,    null: false, foreign_key: true
      t.decimal :quantity_per_unit, precision: 10, scale: 3, default: 1, null: false

      t.timestamps
    end

    add_index :option_choice_ingredients,
              [:option_choice_id, :ingredient_id],
              unique: true,
              name: "idx_oci_choice_ingredient"
  end
end
