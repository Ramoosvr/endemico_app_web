class CashCount < ApplicationRecord
  KINDS = %w[apertura cierre].freeze
  SHIFTS = %w[manana tarde].freeze
  SHIFT_LABELS = { "manana" => "Mañana (6:00 – 14:00)", "tarde" => "Tarde (14:00 – 21:00)" }.freeze
  DENOMINATIONS = [ 1, 2, 5, 10, 20, 50, 100, 200, 500 ].freeze

  belongs_to :user

  validates :kind,  inclusion: { in: KINDS }
  validates :shift, inclusion: { in: SHIFTS }, allow_nil: true
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

  def shift_label
    SHIFT_LABELS[shift] || "—"
  end

  # Rango del turno dado una fecha
  def self.shift_range(date, shift)
    case shift
    when "manana" then Time.zone.parse("#{date} 06:00")..Time.zone.parse("#{date} 14:00")
    when "tarde"  then Time.zone.parse("#{date} 14:00")..Time.zone.parse("#{date} 21:00")
    end
  end

  def self.current_shift
    hour = Time.current.hour
    hour < 14 ? "manana" : "tarde"
  end

  # Ventas registradas por el sistema en el turno
  def self.sales_in_shift(date, shift)
    range = shift_range(date, shift)
    return {} unless range

    orders = Order.completed.where(completed_at: range)
    totals = Order::PAYMENT_METHODS.to_h { |m| [ m, 0.to_d ] }
    orders.each do |o|
      key = o.payment_method.presence
      totals[key] += o.total if key && totals.key?(key)
    end
    totals.merge(total: orders.sum(&:total))
  end
end
