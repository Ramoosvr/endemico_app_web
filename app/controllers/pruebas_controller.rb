class PruebasController < ApplicationController
  def index
    @products = Product.active.includes(:product_ingredients, option_groups: :option_choices)
                        .order(:kind, :name)
                        .group_by(&:kind)

    @recent = Order.where(payment_method: "cortesía")
                   .where("completed_at >= ?", 30.days.ago)
                   .includes(:user, order_items: :product)
                   .order(completed_at: :desc)
                   .limit(100)
  end

  def consume
    product = Product.find(params[:product_id])
    reason  = params[:reason].to_s.strip.presence
    note    = reason == "prueba" ? "PRUEBA — admin" : "CORTESÍA — admin"
    note    = "#{note} (#{params[:note]})" if params[:note].present?

    order = current_user.orders.create!(status: "open", total: 0)
    order.order_items.create!(
      product: product,
      quantity: 1,
      unit_price: 0,
      modifiers_price: 0,
      line_total: 0,
      notes: note
    )
    order.order_items.first.recalc_line_total!
    order.recalc_total!
    order.complete!(payment_method: "cortesía")

    redirect_to pruebas_path, notice: "#{product.name} consumido como #{reason || "cortesía"}. Stock descontado."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to pruebas_path, alert: "No se pudo registrar: #{e.message}"
  end
end
