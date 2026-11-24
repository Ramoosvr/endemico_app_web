class CashCountsController < ApplicationController
  before_action :require_admin!, only: :index

  def index
    @counts = CashCount.includes(:user).recent.limit(100)
    @today_aperturas = CashCount.aperturas.where(created_at: Date.current.all_day).includes(:user)
    @today_cierres   = CashCount.cierres.where(created_at: Date.current.all_day).includes(:user)
  end

  def new
    @kind = params[:kind].to_s.presence_in(CashCount::KINDS) || "apertura"
    @cash_count = CashCount.new(kind: @kind)
  end

  def create
    @cash_count = current_user.cash_counts.build(cash_count_params)
    if @cash_count.save
      redirect_to main_path, notice: "Corte de #{@cash_count.kind_label.downcase} guardado: $#{format('%.2f', @cash_count.total)}."
    else
      @kind = @cash_count.kind
      render :new, status: :unprocessable_entity
    end
  end

  private

  def cash_count_params
    permitted = [:kind, :notes] + CashCount::DENOMINATIONS.map { |d| :"d#{d}" }
    params.require(:cash_count).permit(*permitted)
  end
end
