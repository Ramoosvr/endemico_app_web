class CashWithdrawalsController < ApplicationController
  before_action :require_admin!

  def create
    amount = params[:amount].to_s.gsub(",", ".").to_d rescue 0.to_d
    if amount <= 0
      redirect_to main_path, alert: "Monto inválido para retiro." and return
    end
    withdrawal = current_user.cash_withdrawals.create!(
      amount: amount,
      reason: params[:reason].to_s.strip.presence
    )
    redirect_to main_path, notice: "Retiro de caja registrado: $#{format('%.2f', withdrawal.amount)}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to main_path, alert: "No se pudo registrar el retiro: #{e.message}"
  end
end
