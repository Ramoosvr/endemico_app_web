class ClipPaymentsController < ApplicationController
  FINAL_STATES   = %w[approved declined cancelled error].freeze
  PENDING_STATES = %w[pending created in_progress].freeze

  def create
    @order = current_order
    if @order.order_items.empty?
      redirect_to main_path, alert: "El carrito está vacío." and return
    end

    clip = ClipPinpad.new
    response = clip.create_payment(amount: @order.total, reference: "endemico-order-#{@order.id}")

    request_id = extract_request_id(response)
    if request_id.blank?
      raise ClipPinpad::APIError, "Clip no devolvió un pinpadRequestId. Respuesta: #{response.inspect}"
    end

    @order.update!(
      clip_request_id: request_id,
      clip_status: "pending",
      payment_method: "tarjeta",
      clip_last_checked_at: Time.current
    )
    redirect_to clip_payment_path
  rescue ClipPinpad::NotConfigured => e
    redirect_to ajustes_path, alert: e.message
  rescue ClipPinpad::APIError => e
    redirect_to main_path, alert: "Clip: #{e.message}"
  end

  def show
    @order = current_order_or_nil
    if @order.nil? || @order.clip_request_id.blank?
      redirect_to main_path and return
    end

    # Poll the latest status from Clip (throttled to once every 2s)
    refresh_from_clip! if can_refresh?

    @status = @order.clip_status

    respond_to do |format|
      format.html
      format.json { render json: { status: @status, order_id: @order.id, total: @order.total.to_f } }
    end
  end

  def destroy
    @order = current_order_or_nil
    if @order.nil? || @order.clip_request_id.blank?
      redirect_to main_path and return
    end

    clip = ClipPinpad.new
    clip.cancel_payment(@order.clip_request_id)

    @order.update!(clip_status: "cancelled")
    redirect_to main_path, notice: "Cobro con tarjeta cancelado."
  rescue ClipPinpad::APIError => e
    redirect_to clip_payment_path, alert: "No se pudo cancelar: #{e.message}"
  end

  private

  def can_refresh?
    @order.clip_last_checked_at.nil? || @order.clip_last_checked_at < 2.seconds.ago
  end

  def refresh_from_clip!
    clip = ClipPinpad.new
    response = clip.get_payment(@order.clip_request_id)
    status = normalize_status(response)

    @order.update!(clip_status: status, clip_last_checked_at: Time.current)

    if status == "approved"
      @order.complete!(payment_method: "tarjeta") if @order.status == "open"
    end
  rescue ClipPinpad::APIError => e
    Rails.logger.warn("[Clip] refresh error: #{e.message}")
  end

  def normalize_status(response)
    raw =
      if response.is_a?(Hash)
        response["status"] || response["state"] || response.dig("payment", "status")
      end
    case raw.to_s.downcase
    when "approved", "paid", "completed", "success"    then "approved"
    when "declined", "rejected", "failure", "failed"   then "declined"
    when "cancelled", "canceled", "void"               then "cancelled"
    when "pending", "created", "in_progress", "sent"   then "pending"
    else raw.to_s.presence || "pending"
    end
  end

  def extract_request_id(response)
    return nil unless response.is_a?(Hash)
    response["pinpadRequestId"] ||
      response["pinpad_request_id"] ||
      response.dig("data", "pinpadRequestId") ||
      response["id"]
  end
end
