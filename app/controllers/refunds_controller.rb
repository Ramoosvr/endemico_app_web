class RefundsController < ApplicationController
  before_action :require_admin!, only: [ :index ]

  def index
    @from = parse_date(params[:from]) || 24.hours.ago
    @to   = parse_date(params[:to])   || Time.current

    @orders = Order.completed
                   .where(completed_at: @from..@to)
                   .includes(:user, order_items: :product)
                   .order(completed_at: :desc)
                   .limit(200)

    @recent_refunds = Order.refunded
                           .where(refunded_at: 7.days.ago..Time.current)
                           .includes(:user, :refunded_by_user, order_items: :product)
                           .order(refunded_at: :desc)
                           .limit(30)
  end

  def create
    unless admin? || valid_pin?(params[:pin])
      redirect_back_or_to(pendientes_path, allow_other_host: false, alert: "PIN inválido. Pide al admin el código de autorización.") and return
    end

    if params[:prepared].blank?
      redirect_back_or_to(pendientes_path, allow_other_host: false, alert: "Indica si el pedido ya se preparó.") and return
    end

    prepared = ActiveModel::Type::Boolean.new.cast(params[:prepared])
    order = Order.completed.find(params[:order_id])
    order.refund!(reason: params[:reason], user: current_user, prepared: prepared)
    detail = prepared ? "Los insumos se registraron como merma." : "Los insumos regresaron al stock."
    redirect_back_or_to(pendientes_path, allow_other_host: false, notice: "Pedido ##{order.id} devuelto. #{detail}")
  rescue ActiveRecord::RecordNotFound
    redirect_back_or_to(pendientes_path, allow_other_host: false, alert: "El pedido no existe o ya fue devuelto.")
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_back_or_to(pendientes_path, allow_other_host: false, alert: "No se pudo devolver: #{e.message}")
  end

  private

  def valid_pin?(pin)
    expected = Setting.get(:refund_pin).to_s.strip
    return false if expected.blank?
    pin.to_s.strip == expected
  end

  def parse_date(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
