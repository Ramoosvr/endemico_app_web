class PedidosController < ApplicationController
  def index
    @order = current_order
    @items = @order.order_items.includes(:product, :removed_ingredients, :extras, :chosen_options)
  end
end
