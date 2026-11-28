class MermasController < ApplicationController
  def index
    @ingredients = Ingredient.by_section.group_by(&:section_label)
    range = 30.days.ago..Time.current
    recent = Merma.includes(:ingredient, :user)
                  .where(created_at: range)
                  .order(created_at: :desc)
                  .limit(200)
                  .to_a

    # Insumos sent to merma by a "ya se preparó" refund are summarized under
    # their order below; this list keeps only mermas registered by hand.
    @recent = recent.reject(&:from_refund?)
    @refund_insumos = recent.select(&:from_refund?).group_by { |m| m.reason[/#(\d+)/, 1].to_i }

    @prepared_refunds = Order.refunded
                             .where(refund_prepared: true, refunded_at: range)
                             .includes(:refunded_by_user, order_items: :product)
                             .order(refunded_at: :desc)
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
