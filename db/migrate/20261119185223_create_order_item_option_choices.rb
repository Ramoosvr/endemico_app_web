class CreateOrderItemOptionChoices < ActiveRecord::Migration[8.1]
  def change
    create_table :order_item_option_choices do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :option_choice, null: false, foreign_key: true
      t.string :option_group_name, null: false
      t.string :choice_name, null: false
      t.decimal :extra_price, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :order_item_option_choices,
              [:order_item_id, :option_choice_id],
              unique: true,
              name: "index_oi_choices_on_item_and_choice"
  end
end
