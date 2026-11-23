class ReportesController < ApplicationController
  before_action :require_admin!

  PER_PAGE = 100

  def index
    @from = parse_date(params[:from]) || 30.days.ago.beginning_of_day
    @to   = parse_date(params[:to])   || Time.current.end_of_day
    @status = params[:status].presence
    @method = params[:method].presence
    @user_id = params[:user_id].presence

    scope = Order.where(status: %w[completed cancelled])
                 .where("(orders.completed_at BETWEEN ? AND ?) OR (orders.updated_at BETWEEN ? AND ?)", @from, @to, @from, @to)
                 .includes(:user, order_items: :product)
                 .order(Arel.sql("COALESCE(orders.completed_at, orders.updated_at) DESC"))

    scope = scope.where(status: @status)             if @status.present?
    scope = scope.where(payment_method: @method)     if @method.present?
    scope = scope.where(user_id: @user_id)           if @user_id.present?

    @orders = scope.limit(PER_PAGE)

    @summary = {
      count:      scope.count,
      completed:  scope.where(status: "completed").count,
      cancelled:  scope.where(status: "cancelled").count,
      revenue:    scope.where(status: "completed").sum(:total),
      by_method:  scope.where(status: "completed").group(:payment_method).sum(:total),
      by_user:    scope.joins(:user).where(status: "completed").group("users.name").sum(:total)
    }

    @users = User.order(:name)
  end

  private

  def parse_date(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s) rescue nil
  end
end
