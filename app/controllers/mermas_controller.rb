class MermasController < ApplicationController
  def index
    @ingredients = Ingredient.by_section.group_by(&:section_label)
    @recent = Merma.includes(:ingredient, :user)
                   .where(created_at: 30.days.ago..Time.current)
                   .order(created_at: :desc)
                   .limit(200)
  end

  def create
    ingredient = Ingredient.find(params[:ingredient_id])
    amount = params[:amount].to_s.gsub(",", ".").to_d rescue 0.to_d

    if amount <= 0
      redirect_to merma_path, alert: "La cantidad debe ser mayor que 0." and return
    end

    Merma.create!(
      ingredient: ingredient,
      user: current_user,
      amount: amount,
      reason: params[:reason].to_s.strip.presence
    )

    redirect_to merma_path, notice: "Merma registrada: #{amount} #{ingredient.unit} de #{ingredient.name}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to merma_path, alert: "No se pudo registrar: #{e.message}"
  end
end
