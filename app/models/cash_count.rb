class CashCount < ApplicationRecord
  KINDS = %w[apertura cierre].freeze
  DENOMINATIONS = [1, 2, 5, 10, 20, 50, 100, 200, 500].freeze

  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  DENOMINATIONS.each do |d|
    validates :"d#{d}", numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end

  before_save :recalc_total

  scope :aperturas, -> { where(kind: "apertura") }
  scope :cierres,   -> { where(kind: "cierre") }
  scope :recent,    -> { order(created_at: :desc) }

  def recalc_total
    self.total = DENOMINATIONS.sum { |d| public_send("d#{d}").to_i * d }
  end

  def kind_label
    kind == "apertura" ? "Entrada" : "Salida"
  end
end
