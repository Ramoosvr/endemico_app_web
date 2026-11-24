class AddCustomerNameToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :customer_name, :string
  end
end
