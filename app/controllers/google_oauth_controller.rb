require "googleauth"
require "google/apis/drive_v3"

class GoogleOauthController < ApplicationController
  SCOPE = "https://www.googleapis.com/auth/drive.file"

  def authorize
    state = SecureRandom.hex(16)
    session[:google_oauth_state] = state

    params_hash = {
      client_id: client_id,
      redirect_uri: callback_url,
      response_type: "code",
      scope: SCOPE,
      access_type: "offline",
      prompt: "consent",
      state: state
    }
    redirect_to "https://accounts.google.com/o/oauth2/v2/auth?#{params_hash.to_query}",
                allow_other_host: true
  end

  def callback
    if params[:error].present?
      redirect_to corte_path, alert: "Conexión con Google cancelada (#{params[:error]})." and return
    end

    expected_state = session.delete(:google_oauth_state)
    if expected_state.blank? || expected_state != params[:state]
      redirect_to corte_path, alert: "Estado OAuth inválido. Intenta de nuevo." and return
    end

    authorizer = Signet::OAuth2::Client.new(
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: callback_url,
      code: params[:code]
    )
    authorizer.fetch_access_token!

    if authorizer.refresh_token.blank?
      redirect_to corte_path, alert: "Google no devolvió refresh token. Revoca el acceso en tu cuenta y reconéctate." and return
    end

    current_user.update!(
      google_refresh_token: authorizer.refresh_token,
      google_token_expires_at: Time.current + authorizer.expires_in.to_i.seconds
    )
    redirect_to corte_path, notice: "Google Drive conectado."
  rescue Signet::AuthorizationError => e
    redirect_to corte_path, alert: "Error autorizando con Google: #{e.message}"
  end

  def destroy
    current_user.update!(google_refresh_token: nil, google_token_expires_at: nil)
    redirect_to corte_path, notice: "Google Drive desconectado."
  end

  private

  def client_id
    Rails.application.credentials.dig(:google_drive, :client_id) || ENV["GOOGLE_DRIVE_CLIENT_ID"]
  end

  def client_secret
    Rails.application.credentials.dig(:google_drive, :client_secret) || ENV["GOOGLE_DRIVE_CLIENT_SECRET"]
  end

  def callback_url
    google_oauth_callback_url
  end
end
