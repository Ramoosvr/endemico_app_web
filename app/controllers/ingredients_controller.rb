class IngredientsController < ApplicationController
  before_action :require_admin!
  before_action :set_ingredient, only: [ :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html do
        @ingredients = Ingredient.ordered
        @ingredients_by_category = @ingredients.group_by { |i| i.category.presence || "otros" }
          .sort_by { |cat, _| Ingredient::CATEGORIES.index(cat) || 99 }
        @new_ingredient = Ingredient.new(unit: "pza", category: "otros")
      end
      format.json do
        render json: Ingredient.ordered.select(:id, :name)
      end
    end
  end

  def create
    # JSON path (used by the product configuration UI)
    if request.format.json? || params[:ingredient].is_a?(ActionController::Parameters) && params[:ingredient][:unit].blank?
      name = params.dig(:ingredient, :name).to_s.strip
      if name.blank?
        return render json: { error: "Nombre requerido" }, status: :unprocessable_entity
      end

      ing = Ingredient.find_by("LOWER(name) = ?", name.downcase) || Ingredient.create(name: name, unit: "pza")

      if ing.persisted?
        render json: { id: ing.id, name: ing.name }, status: :created
      else
        render json: { error: ing.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
      return
    end

    # HTML path from /insumos backoffice
    @ingredient = Ingredient.new(ingredient_params)
    if @ingredient.save
      redirect_to ingredients_path, notice: "Insumo creado."
    else
      @ingredients = Ingredient.ordered
      @ingredients_by_category = @ingredients.group_by { |i| i.category.presence || "otros" }
        .sort_by { |cat, _| Ingredient::CATEGORIES.index(cat) || 99 }
      @new_ingredient = @ingredient
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ingredient.update(ingredient_params)
      redirect_to ingredients_path, notice: "Insumo actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ingredient.destroy
    redirect_to ingredients_path, notice: "Insumo eliminado."
  end

  private

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name, :unit, :stock, :min_stock, :cost_per_unit, :supplier, :category)
  end
end
