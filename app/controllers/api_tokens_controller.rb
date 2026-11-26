class ApiTokensController < ApplicationController
  before_action :require_admin!

  def index
    @tokens = ApiToken.order(created_at: :desc)
    @new_token_raw = flash[:new_token_raw]
  end

  def create
    name = params[:name].to_s.strip
    scopes = Array(params[:scopes]).reject(&:blank?).join(",").presence || "read,write"

    if name.blank?
      redirect_to api_tokens_path, alert: "Nombre requerido." and return
    end

    token, raw = ApiToken.build_with_token(name: name, scopes: scopes)
    token.save!

    flash[:new_token_raw] = raw
    redirect_to api_tokens_path, notice: "Token '#{name}' creado. Cópialo ahora — no se vuelve a mostrar."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to api_tokens_path, alert: "No se pudo crear: #{e.message}"
  end

  def destroy
    token = ApiToken.find(params[:id])
    token.revoke!
    redirect_to api_tokens_path, notice: "Token '#{token.name}' revocado."
  end
end
