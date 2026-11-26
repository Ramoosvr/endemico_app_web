class MainController < ApplicationController
  FEATURED_LIMIT = 50

  BEBIDA_SUBKIND_ORDER = %w[cafe_negro cafe_con_leche chai_caliente chai_frio frios refrescos otro].freeze

  def index
    includes = [:product_ingredients, { option_groups: :option_choices }]

    @bebidas = featured_or_fallback("bebida", includes)
    @bebidas_by_subkind = @bebidas
                           .group_by { |p| p.subkind.presence || "otro" }
                           .sort_by { |sub, _| BEBIDA_SUBKIND_ORDER.index(sub) || 99 }
    @comida  = featured_or_fallback("comida", includes)
    @postres = featured_or_fallback("postre", includes)

    @order       = current_order
    @order_items = @order.order_items.includes(:product, :removed_ingredients, :extras, :chosen_options)
  end

  private

  def featured_or_fallback(kind, includes)
    scope = Product.where(kind: kind).includes(includes)
    featured = scope.where(featured: true).order(:name).limit(FEATURED_LIMIT).to_a
    return featured if featured.any?
    scope.order(:name).limit(FEATURED_LIMIT).to_a
  end
end
