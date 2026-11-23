class AddUsdFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :usd_received, :decimal, precision: 10, scale: 2
    add_column :orders, :usd_rate,     :decimal, precision: 8,  scale: 4
  end
end
