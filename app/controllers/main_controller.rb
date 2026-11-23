class MainController < ApplicationController
  def index
    @bebidas = Product.bebidas.includes(:product_ingredients, option_groups: :option_choices)
    @comida  = Product.comidas.includes(:product_ingredients, option_groups: :option_choices)
    @postres = Product.postres.includes(:product_ingredients, option_groups: :option_choices)
    @order   = current_order
    @order_items = @order.order_items.includes(:product, :removed_ingredients, :extras, :chosen_options)
  end
end
