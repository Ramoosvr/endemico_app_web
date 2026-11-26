class AddRefundFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :refunded_at, :datetime
    add_column :orders, :refund_reason, :text
    add_reference :orders, :refunded_by_user, foreign_key: { to_table: :users }
    add_index :orders, :refunded_at
  end
end
