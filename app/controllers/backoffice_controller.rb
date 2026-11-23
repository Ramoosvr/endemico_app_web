class BackofficeController < ApplicationController
  before_action :require_admin!

  def index
    @alerts = Ingredient.below_min.count
    @products_count = Product.count
    @ingredients_count = Ingredient.count
    @users_count = User.count
    @ai_enabled = Setting.get(:ai_enabled)
  end
end
