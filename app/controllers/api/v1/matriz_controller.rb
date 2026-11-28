module Api
  module V1
    # Endpoint used by the Apps Script inside the "Matriz" Google Sheet.
    #   POST /api/v1/matriz/sync   -> applies sheet changes, returns POS stock
    #   GET  /api/v1/matriz/stock  -> only returns POS stock
    class MatrizController < BaseController
      before_action -> { require_scope!("write") }, only: [ :sync ]
      before_action -> { require_scope!("read") },  only: [ :stock ]

      def sync
        payload = parsed_body
        return render(json: { ok: false, errores: [ "JSON inválido" ] }, status: :bad_request) unless payload
        result = Matriz::Sync.new(payload).call
        render json: result.response
      end

      def stock
        render json: Matriz::Sync.new({}).response
      end

      private

      # The sheet sends free-form grids (Recetario), so the body is read as
      # plain JSON instead of going through strong parameters.
      def parsed_body
        raw = request.raw_post.to_s
        return {} if raw.strip.empty?

        data = JSON.parse(raw)
        data.is_a?(Hash) ? data : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end
