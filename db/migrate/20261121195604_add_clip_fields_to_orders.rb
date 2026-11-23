class AddClipFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :clip_request_id,       :string
    add_column :orders, :clip_status,           :string
    add_column :orders, :clip_last_checked_at,  :datetime
    add_index  :orders, :clip_request_id
  end
end
