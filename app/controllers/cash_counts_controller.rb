class CashCountsController < ApplicationController
  before_action :set_cash_count, only: :show

  def index
    scope = CashCount.includes(:user).recent
    scope = scope.where(user: current_user) unless admin?
    @counts = scope.limit(100)
    @today_aperturas = CashCount.aperturas.where(created_at: Date.current.all_day).includes(:user)
    @today_cierres   = CashCount.cierres.where(created_at: Date.current.all_day).includes(:user)

    wscope = CashWithdrawal.includes(:user).recent
    wscope = wscope.where(user: current_user) unless admin?
    @withdrawals = wscope.limit(50)
    @today_withdrawals = CashWithdrawal.today.includes(:user)
  end

  def show
    @sales = nil
    if @cash_count.shift.present? && @cash_count.kind == "cierre"
      @sales = CashCount.sales_in_shift(@cash_count.created_at.to_date, @cash_count.shift)
    end
  end

  def new
    @kind  = params[:kind].to_s.presence_in(CashCount::KINDS) || "apertura"
    @shift = params[:shift].to_s.presence_in(CashCount::SHIFTS) || CashCount.current_shift
    @cash_count = CashCount.new(kind: @kind, shift: @shift)
    @sales = CashCount.sales_in_shift(Date.current, @shift) if @kind == "cierre"
  end

  def create
    @cash_count = current_user.cash_counts.build(cash_count_params)
    if @cash_count.save
      redirect_to cash_count_path(@cash_count), notice: "Corte de #{@cash_count.kind_label.downcase} guardado: $#{format('%.2f', @cash_count.total)}."
    else
      @kind  = @cash_count.kind
      @shift = @cash_count.shift || CashCount.current_shift
      @sales = CashCount.sales_in_shift(Date.current, @shift) if @kind == "cierre"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_cash_count
    @cash_count = admin? ? CashCount.find(params[:id]) : current_user.cash_counts.find(params[:id])
  end

  def cash_count_params
    permitted = [
      :kind, :shift, :notes,
      :sold_cash, :sold_card, :sold_usd, :sold_transfer
    ] + CashCount::DENOMINATIONS.map { |d| :"d#{d}" }
    params.require(:cash_count).permit(*permitted)
  end
end
