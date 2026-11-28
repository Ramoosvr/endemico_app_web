module Api
  module V1
    class ProductsController < BaseController
      before_action -> { require_scope!("read")  }, only: [ :index, :show ]
      before_action -> { require_scope!("write") }, only: [ :create, :update, :destroy ]
      before_action :set_product, only: [ :show, :update, :destroy ]

      def index
        scope = Product.includes(product_ingredients: :ingredient, option_groups: :option_choices)
        scope = scope.where(kind: params[:kind]) if params[:kind].present?
        render json: scope.order(:kind, :name).map { |p| serialize(p) }
      end

      def show
        render json: serialize(@product)
      end

      def create
        if product_params[:external_id].present?
          @product = Product.find_or_initialize_by(external_id: product_params[:external_id])
        else
          @product = Product.new
        end
        @product.assign_attributes(product_params)
        @product.save!
        render json: serialize(@product), status: @product.previously_new_record? ? :created : :ok
      end

      def update
        @product.update!(product_params)
        render json: serialize(@product)
      end

      def destroy
        @product.destroy!
        head :no_content
      end

      private

      def set_product
        @product = if params[:id].to_s.match?(/\A\d+\z/)
                     Product.find(params[:id])
        else
                     Product.find_by!(external_id: params[:id])
        end
      end

      def product_params
        params.require(:product).permit(
          :external_id, :name, :kind, :subkind, :price, :cost,
          :stock, :featured, :active
        )
      end

      def serialize(p)
        {
          id: p.id,
          external_id: p.external_id,
          name: p.name,
          kind: p.kind,
          subkind: p.subkind,
          price: p.price.to_f,
          cost: p.cost.to_f,
          stock: p.stock.to_i,
          featured: p.featured,
          active: p.active,
          customizable: p.customizable?,
          ingredients: p.product_ingredients.map { |pi|
            {
              id: pi.id,
              ingredient_id: pi.ingredient_id,
              ingredient_external_id: pi.ingredient&.external_id,
              name: pi.ingredient&.name,
              default_included: pi.default_included,
              extra_price: pi.extra_price.to_f,
              quantity_per_unit: pi.quantity_per_unit.to_f,
              position: pi.position
            }
          },
          option_groups: p.option_groups.map { |og|
            {
              id: og.id,
              external_id: og.external_id,
              name: og.name,
              selection_mode: og.selection_mode,
              required: og.required,
              position: og.position,
              choices: og.option_choices.map { |oc|
                {
                  id: oc.id,
                  external_id: oc.external_id,
                  name: oc.name,
                  extra_price: oc.extra_price.to_f,
                  default_selected: oc.default_selected,
                  position: oc.position
                }
              }
            }
          }
        }
      end
    end
  end
end
