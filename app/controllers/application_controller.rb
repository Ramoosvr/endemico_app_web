class ApplicationController < ActionController::Base
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user, :logged_in?, :admin?, :current_order, :current_order_or_nil

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def admin?
    current_user&.admin?
  end

  def require_login
    redirect_to login_path unless logged_in?
  end

  def require_admin!
    return if admin?
    redirect_to main_path, alert: "Esa sección es solo para administradores."
  end

  def current_order
    return nil unless current_user
    @current_order ||= current_user.orders.open.first || current_user.orders.create!(status: "open", total: 0)
  end

  def current_order_or_nil
    return nil unless current_user
    current_user.orders.open.first
  end
end
