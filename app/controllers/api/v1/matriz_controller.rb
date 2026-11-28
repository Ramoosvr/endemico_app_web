module Api
  module V1
    # Endpoint used by the Apps Script inside the "Matriz" Google Sheet.
    #   POST /api/v1/matriz/sync   -> applies sheet changes, returns POS stock
    #   GET  /api/v1/matriz/stock  -> only returns POS stock
    class MatrizController < BaseController
      before_action -> { require_scope!("write") }, only: [ :sync ]
      before_action -> { require_scope!("read") },  only: [ :stock ]

      def sync
        payload = params.permit!.to_h.except("controller", "action", "matriz", "format")
        result = Matriz::Sync.new(payload).call
        render json: result.response
      end

      def stock
        render json: Matriz::Sync.new({}).response
      end
    end
  end
end
