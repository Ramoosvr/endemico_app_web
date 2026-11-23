require "googleauth"
require "google/apis/drive_v3"

module Drive
  class Uploader
    class MissingCredentials < StandardError; end
    class NotConnected < StandardError; end

    def initialize(user)
      @user = user
    end

    def upload(io:, filename:, mime_type: "text/csv")
      raise NotConnected, "Usuario sin refresh token de Google" if @user.google_refresh_token.blank?
      raise MissingCredentials, "Falta client_id/secret/folder_id en credenciales" unless credentials_present?

      drive = Google::Apis::DriveV3::DriveService.new
      drive.authorization = authorizer

      metadata = Google::Apis::DriveV3::File.new(
        name: filename,
        parents: [folder_id]
      )
      drive.create_file(metadata, upload_source: io, content_type: mime_type, fields: "id, name, web_view_link")
    end

    private

    def authorizer
      client = Signet::OAuth2::Client.new(
        token_credential_uri: "https://oauth2.googleapis.com/token",
        client_id: client_id,
        client_secret: client_secret,
        refresh_token: @user.google_refresh_token
      )
      client.fetch_access_token!
      client
    end

    def credentials_present?
      client_id.present? && client_secret.present? && folder_id.present?
    end

    def client_id
      Rails.application.credentials.dig(:google_drive, :client_id) || ENV["GOOGLE_DRIVE_CLIENT_ID"]
    end

    def client_secret
      Rails.application.credentials.dig(:google_drive, :client_secret) || ENV["GOOGLE_DRIVE_CLIENT_SECRET"]
    end

    def folder_id
      Rails.application.credentials.dig(:google_drive, :folder_id) || ENV["GOOGLE_DRIVE_FOLDER_ID"]
    end
  end
end
