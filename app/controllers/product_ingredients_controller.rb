class ProductIngredientsController < ApplicationController
  before_action :require_admin!
  before_action :set_product
  before_action :set_product_ingredient, only: [ :update, :destroy ]

  def create
    ingredient_id = params.dig(:product_ingredient, :ingredient_id)

    if ingredient_id.blank? && params.dig(:product_ingredient, :new_ingredient_name).present?
      ingredient = find_or_create_ingredient(params[:product_ingredient][:new_ingredient_name])
      ingredient_id = ingredient&.id
    end

    raw_price = params.dig(:product_ingredient, :extra_price)
    extra_price = raw_price.present? ? raw_price.to_d : @product.suggested_extra_price

    qty = params.dig(:product_ingredient, :quantity_per_unit).to_d

    pi = @product.product_ingredients.build(
      ingredient_id: ingredient_id,
      default_included: param_bool(:default_included, true),
      extra_price: extra_price,
      quantity_per_unit: qty,
      position: @product.product_ingredients.maximum(:position).to_i + 1
    )

    if pi.save
      redirect_to product_path(@product), notice: "Ingrediente agregado."
    else
      redirect_to product_path(@product), alert: pi.errors.full_messages.to_sentence
    end
  end

  def update
    if @product_ingredient.update(permitted_params)
      redirect_to product_path(@product), notice: "Ingrediente actualizado."
    else
      redirect_to product_path(@product), alert: @product_ingredient.errors.full_messages.to_sentence
    end
  end

  def destroy
    @product_ingredient.destroy
    redirect_to product_path(@product), notice: "Ingrediente eliminado."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_product_ingredient
    @product_ingredient = @product.product_ingredients.find(params[:id])
  end

  def permitted_params
    params.require(:product_ingredient).permit(:default_included, :extra_price, :quantity_per_unit)
  end

  def param_bool(key, default)
    val = params.dig(:product_ingredient, key)
    return default if val.nil?
    ActiveModel::Type::Boolean.new.cast(val)
  end

  def find_or_create_ingredient(name)
    name = name.to_s.strip
    return nil if name.blank?
    Ingredient.find_by("LOWER(name) = ?", name.downcase) || Ingredient.create(name: name)
  end
end
