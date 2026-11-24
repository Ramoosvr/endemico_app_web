class AddCashReceivedToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :cash_received, :decimal, precision: 10, scale: 2
  end
end
