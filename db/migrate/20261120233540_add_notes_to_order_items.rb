class AddNotesToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :notes, :text
  end
end
