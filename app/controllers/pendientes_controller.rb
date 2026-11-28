class PendientesController < ApplicationController
  def index
    @orders = Order.pending_preparation
                   .includes(:user, order_items: [ :product, :removed_ingredients, :extras, :chosen_options ])
                   .order(:completed_at)
  end

  def mark_prepared
    order = Order.find(params[:id])
    order.update!(prepared_at: Time.current)
    redirect_to pendientes_path, notice: "Pedido ##{order.id} marcado como hecho."
  end

  def mark_all_prepared
    count = Order.pending_preparation.update_all(prepared_at: Time.current)
    redirect_to pendientes_path, notice: "#{count} pedido#{count == 1 ? '' : 's'} marcados como hechos."
  end
end
