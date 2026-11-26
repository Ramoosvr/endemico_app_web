module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token!

      rescue_from ActiveRecord::RecordNotFound,  with: :not_found
      rescue_from ActiveRecord::RecordInvalid,   with: :unprocessable
      rescue_from ActionController::ParameterMissing, with: :bad_request

      attr_reader :current_token

      def require_scope!(scope)
        return if current_token&.can?(scope)
        render json: { error: "forbidden", scope: scope }, status: :forbidden
      end

      private

      def authenticate_token!
        header = request.authorization.to_s
        raw = header.start_with?("Bearer ") ? header.sub("Bearer ", "").strip : nil
        @current_token = ApiToken.authenticate(raw)
        unless @current_token
          render json: { error: "unauthorized" }, status: :unauthorized
          return
        end
        @current_token.touch_usage!
      end

      def not_found(e)
        render json: { error: "not_found", detail: e.message }, status: :not_found
      end

      def unprocessable(e)
        render json: { error: "unprocessable", errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def bad_request(e)
        render json: { error: "bad_request", detail: e.message }, status: :bad_request
      end
    end
  end
end
