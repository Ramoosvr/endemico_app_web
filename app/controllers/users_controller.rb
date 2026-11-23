class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: [ :edit, :update, :destroy ]

  def index
    @users = User.order(:role, :name)
    @new_user = User.new(role: "barista")
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to usuarios_path, notice: "#{@user.name} creado como #{@user.role}."
    else
      @users = User.order(:role, :name)
      @new_user = @user
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attrs = user_params.to_h
    attrs.delete("password") if attrs["password"].blank?
    attrs.delete("password_confirmation") if attrs["password"].blank?

    if @user.update(attrs)
      redirect_to usuarios_path, notice: "#{@user.name} actualizado."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to usuarios_path, alert: "No puedes eliminarte a ti mismo." and return
    end
    name = @user.name
    @user.destroy
    redirect_to usuarios_path, notice: "#{name} eliminado."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :password, :password_confirmation, :role)
  end
end
