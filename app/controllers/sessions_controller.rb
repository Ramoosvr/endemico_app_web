class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    redirect_to main_path and return if logged_in?
  end

  def create
    user = User.find_by(name: params[:name].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to main_path
    else
      flash.now[:alert] = "Nombre o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path
  end
end
