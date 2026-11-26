class AddPreparedAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :prepared_at, :datetime
    add_index :orders, :prepared_at
  end
end
