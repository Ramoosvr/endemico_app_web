class ProductsController < ApplicationController
  before_action :require_admin!, except: [ :index ]
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @products = Product.order(:kind, :name)
    @product = Product.new
  end

  def new
    @product = Product.new
  end

  def show
    @ingredients_catalog = Ingredient.ordered
    @new_option_group = @product.option_groups.build
    3.times { @new_option_group.option_choices.build }
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to product_path(@product), notice: "#{@product.name} agregado al inventario."
    else
      @products = Product.order(:kind, :name)
      flash.now[:alert] = @product.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to product_path(@product), notice: "#{@product.name} actualizado."
    else
      flash.now[:alert] = @product.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @product.name
    @product.destroy
    redirect_to stock_path, notice: "#{name} eliminado."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :kind, :subkind, :cost, :price, :stock, :photo, :ingredients_list)
  end
end
