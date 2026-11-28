module Api
  module V1
    class IngredientsController < BaseController
      before_action -> { require_scope!("read")  }, only: [ :index, :show ]
      before_action -> { require_scope!("write") }, only: [ :create, :update, :destroy ]
      before_action :set_ingredient, only: [ :show, :update, :destroy ]

      def index
        render json: Ingredient.order(:name).map { |i| serialize(i) }
      end

      def show
        render json: serialize(@ingredient)
      end

      def create
        if ingredient_params[:external_id].present?
          @ingredient = Ingredient.find_or_initialize_by(external_id: ingredient_params[:external_id])
        else
          @ingredient = Ingredient.new
        end
        @ingredient.assign_attributes(ingredient_params)
        @ingredient.save!
        render json: serialize(@ingredient), status: @ingredient.previously_new_record? ? :created : :ok
      end

      def update
        @ingredient.update!(ingredient_params)
        render json: serialize(@ingredient)
      end

      def destroy
        @ingredient.destroy!
        head :no_content
      end

      private

      def set_ingredient
        @ingredient = if params[:id].to_s.match?(/\A\d+\z/)
                        Ingredient.find(params[:id])
        else
                        Ingredient.find_by!(external_id: params[:id])
        end
      end

      def ingredient_params
        params.require(:ingredient).permit(:external_id, :name, :unit, :stock, :min_stock, :cost_per_unit, :supplier)
      end

      def serialize(i)
        {
          id: i.id,
          external_id: i.external_id,
          name: i.name,
          unit: i.unit,
          stock: i.stock.to_f,
          min_stock: i.min_stock.to_f,
          cost_per_unit: i.cost_per_unit.to_f,
          below_min: i.below_min?,
          supplier: i.supplier
        }
      end
    end
  end
end
