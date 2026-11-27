class CatalogoController < ApplicationController
  KIND_LABELS = {
    "bebida" => "Bebidas",
    "comida" => "Comida",
    "postre" => "Postres"
  }.freeze

  def show
    @kind = params[:kind].to_s
    unless Product::KINDS.include?(@kind)
      redirect_to(main_path, alert: "Categoría desconocida.") and return
    end

    products = Product.active.where(kind: @kind)
                      .includes(:product_ingredients, option_groups: :option_choices)
                      .order(:subkind, :name)

    @kind_label = KIND_LABELS[@kind]
    @groups     = products.group_by { |p| p.subkind.presence || "otro" }
                          .sort_by  { |sk, _| Product::SUBKINDS[@kind].index(sk) || 999 }

    @order       = current_order
    @order_items = @order.order_items.includes(:product, :removed_ingredients, :extras, :chosen_options)
  end
end
