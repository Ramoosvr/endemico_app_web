module Api
  module V1
    class SalesController < BaseController
      before_action -> { require_scope!("read") }

      def index
        from = parse_time(params[:desde]) || Time.current.beginning_of_day
        to   = parse_time(params[:hasta]) || Time.current.end_of_day

        orders = Order.completed
                      .where(completed_at: from..to)
                      .includes(:user, order_items: [:product, :removed_ingredients, :extras, :chosen_options])
                      .order(completed_at: :asc)

        render json: {
          desde: from.iso8601,
          hasta: to.iso8601,
          count: orders.size,
          total: orders.sum(&:total).to_f,
          orders: orders.map { |o| serialize(o) }
        }
      end

      private

      def parse_time(str)
        return nil if str.blank?
        Time.zone.parse(str.to_s)
      rescue ArgumentError
        nil
      end

      def serialize(order)
        {
          id: order.id,
          customer_name: order.customer_name,
          user: order.user&.name,
          status: order.status,
          total: order.total.to_f,
          payment_method: order.payment_method,
          cash_received: order.cash_received&.to_f,
          usd_received: order.usd_received&.to_f,
          usd_rate: order.usd_rate&.to_f,
          completed_at: order.completed_at&.iso8601,
          items: order.order_items.map { |i|
            {
              product_id: i.product_id,
              product_external_id: i.product.external_id,
              product_name: i.product.name,
              quantity: i.quantity,
              unit_price: i.unit_price.to_f,
              modifiers_price: i.modifiers_price.to_f,
              line_total: i.line_total.to_f,
              notes: i.notes,
              modifiers: i.modifier_lines
            }
          }
        }
      end
    end
  end
end
