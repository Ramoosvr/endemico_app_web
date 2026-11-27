class AddActiveFlagsAndOptionQuantity < ActiveRecord::Migration[8.1]
  def change
    # Products and option groups that are no longer offered stay in the
    # database (past sales point to them) but are hidden everywhere else.
    add_column :products,      :active, :boolean, default: true, null: false
    add_column :option_groups, :active, :boolean, default: true, null: false

    # Counter options ("Shot extra ×2") store how many were chosen.
    add_column :order_item_option_choices, :quantity, :integer, default: 1, null: false
  end
end
