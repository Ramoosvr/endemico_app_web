class CashWithdrawal < ApplicationRecord
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :today,  -> { where(created_at: Date.current.all_day) }
end
