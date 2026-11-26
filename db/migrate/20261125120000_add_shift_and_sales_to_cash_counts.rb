class AddShiftAndSalesToCashCounts < ActiveRecord::Migration[8.1]
  def change
    add_column :cash_counts, :shift,       :string
    add_column :cash_counts, :sold_cash,   :decimal, precision: 10, scale: 2, default: 0
    add_column :cash_counts, :sold_card,   :decimal, precision: 10, scale: 2, default: 0
    add_column :cash_counts, :sold_usd,    :decimal, precision: 10, scale: 2, default: 0
    add_column :cash_counts, :sold_transfer, :decimal, precision: 10, scale: 2, default: 0

    add_index :cash_counts, :shift
  end
end
