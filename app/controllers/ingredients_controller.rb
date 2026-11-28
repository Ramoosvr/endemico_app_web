class IngredientsController < ApplicationController
  before_action :require_admin!
  before_action :set_ingredient, only: [ :edit, :update, :destroy, :compra ]

  def index
    respond_to do |format|
      format.html do
        load_index
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

      ing = Ingredient.active.find_by("LOWER(name) = ?", name.downcase) || Ingredient.create(name: name, unit: "pza")

      if ing.persisted?
        render json: { id: ing.id, name: ing.name }, status: :created
      else
        render json: { error: ing.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
      return
    end

    # HTML path from /insumos backoffice
    @ingredient = Ingredient.new(ingredient_params.except(:stock))
    initial = number(ingredient_params[:stock])
    if @ingredient.save
      @ingredient.apply_movement!(initial, kind: "compra", user: current_user, note: "Alta en el POS") if initial&.nonzero?
      redirect_to ingredients_path, notice: "Insumo creado. Aparecerá en Matriz en menos de un minuto."
    else
      load_index
      @new_ingredient = @ingredient
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @movements = @ingredient.inventory_movements.recent.includes(:user).limit(30)
  end

  # Stock typed in the form is a physical count: recorded as an adjustment.
  def update
    attrs = ingredient_params
    counted = number(attrs.delete(:stock))
    if @ingredient.update(attrs)
      if counted && counted != @ingredient.stock.to_d
        @ingredient.apply_movement!(counted - @ingredient.stock.to_d, kind: "ajuste", user: current_user,
                                    note: "Conteo capturado en el POS: #{counted}")
      end
      redirect_to ingredients_path, notice: "Insumo actualizado."
    else
      @movements = @ingredient.inventory_movements.recent.limit(30)
      render :edit, status: :unprocessable_entity
    end
  end

  # "Llegó producto": adds to stock, in units or in packages.
  def compra
    amount = number(params[:amount])
    amount *= @ingredient.package_size.to_d if amount && params[:mode] == "paquetes" && @ingredient.package_size.to_d.positive?
    if amount.nil? || amount <= 0
      redirect_to edit_ingredient_path(@ingredient), alert: "Escribe cuánto llegó." and return
    end
    @ingredient.apply_movement!(amount, kind: "compra", user: current_user, note: params[:note].to_s.strip.presence)
    redirect_to ingredients_path, notice: "Entrada registrada: +#{amount.to_f} #{@ingredient.unit} de #{@ingredient.name}."
  end

  # Archive, never delete: sales and mermas keep pointing to it.
  def destroy
    @ingredient.update!(archived_at: Time.current)
    redirect_to ingredients_path, notice: "#{@ingredient.name} archivado."
  end

  def actualizar_recetas
    Matriz::Sync.request_recipes!
    redirect_to recetas_ingredients_path, notice: "Pedido enviado a Matriz. Las recetas se actualizan en menos de un minuto; recarga esta página."
  end

  def recetas
    @result = Matriz::Sync.last_recipe_result
    @requested = Matriz::Sync.recipes_requested?
    @products = Product.active.where(kind: %w[bebida comida postre]).includes(recipe_lines: :ingredient).order(:kind, :subkind, :name)
  end

  def movimientos
    @movements = InventoryMovement.recent.includes(:ingredient, :user).limit(300)
    @sin_receta = OrderItem.where(inventory_status: %w[sin_receta error]).includes(:product, :order)
                           .order(id: :desc).limit(100)
  end

  private

  def load_index
    @ingredients = Ingredient.by_section
    @ingredients_by_section = @ingredients.group_by(&:section_label)
    @sections = Ingredient.active.where.not(section: nil).order(:section_position).distinct.pluck(:section)
  end

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name, :unit, :stock, :min_stock, :cost_per_unit, :supplier, :category,
                                       :section, :brand, :package_size, :package_unit, :package_count, :package_price)
  end

  def number(raw)
    s = raw.to_s.strip.delete(",")
    return nil if s.blank?
    BigDecimal(s)
  rescue ArgumentError
    nil
  end
end
