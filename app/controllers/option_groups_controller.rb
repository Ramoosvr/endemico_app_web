class OptionGroupsController < ApplicationController
  before_action :require_admin!
  before_action :set_product
  before_action :set_option_group, only: [:update, :destroy]

  def create
    og = @product.option_groups.build(permitted_params)
    og.position = @product.option_groups.maximum(:position).to_i + 1

    if og.save
      redirect_to product_path(@product), notice: "Grupo de opciones creado."
    else
      redirect_to product_path(@product), alert: og.errors.full_messages.to_sentence
    end
  end

  def update
    if @option_group.update(permitted_params)
      redirect_to product_path(@product), notice: "Grupo actualizado."
    else
      redirect_to product_path(@product), alert: @option_group.errors.full_messages.to_sentence
    end
  end

  def destroy
    @option_group.destroy
    redirect_to product_path(@product), notice: "Grupo eliminado."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_option_group
    @option_group = @product.option_groups.find(params[:id])
  end

  def permitted_params
    params.require(:option_group).permit(
      :name, :required, :selection_mode,
      option_choices_attributes: [:id, :name, :extra_price, :default_selected, :_destroy]
    )
  end
end
