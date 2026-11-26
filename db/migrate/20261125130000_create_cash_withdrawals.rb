class CreateCashWithdrawals < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_withdrawals do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :reason

      t.timestamps
    end
  end
end
