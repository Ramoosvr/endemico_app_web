require "csv"

class CortesController < ApplicationController
  PERIODS = %w[day week month].freeze

  def index
    @period = PERIODS.include?(params[:period]) ? params[:period] : "day"
    @date = parse_date(params[:date]) || Date.current
    @range_start, @range_end = period_range(@date, @period)

    @orders = Order.completed
                   .where(completed_at: @range_start..@range_end)
                   .includes(:user, order_items: [:product, :removed_ingredients, :extras, :chosen_options])
                   .order(completed_at: :desc)

    @total_revenue = @orders.sum(&:total)
    @total_items   = @orders.sum { |o| o.order_items.sum(&:quantity) }

    @top_products = top_products(@orders)
    @by_kind = by_kind(@orders)
    @by_payment = by_payment(@orders)
    @daily_breakdown = daily_breakdown(@orders) if @period != "day"
    @prev_date, @next_date = navigation_dates(@date, @period)
  end

  def upload_to_drive
    unless current_user.google_refresh_token.present?
      redirect_to google_oauth_authorize_path and return
    end

    period = PERIODS.include?(params[:period]) ? params[:period] : "day"
    date = parse_date(params[:date]) || Date.current
    range_start, range_end = period_range(date, period)

    orders = Order.completed
                  .where(completed_at: range_start..range_end)
                  .includes(:user, order_items: [:product, :removed_ingredients, :extras, :chosen_options])
                  .order(completed_at: :asc)

    if orders.empty?
      redirect_to corte_path(period: period, date: date.iso8601), alert: "Sin pedidos en el rango seleccionado." and return
    end

    csv = build_csv(orders)
    filename = csv_filename(period, date, range_start, range_end)

    Drive::Uploader.new(current_user).upload(
      io: StringIO.new(csv),
      filename: filename,
      mime_type: "text/csv"
    )

    redirect_to corte_path(period: period, date: date.iso8601),
                notice: "Corte subido a Drive como #{filename}."
  rescue Drive::Uploader::MissingCredentials => e
    redirect_to corte_path, alert: "Falta configuración de Google Drive: #{e.message}"
  rescue Signet::AuthorizationError
    current_user.update!(google_refresh_token: nil, google_token_expires_at: nil)
    redirect_to google_oauth_authorize_path, alert: "El permiso con Google venció. Reconecta la cuenta."
  rescue Google::Apis::Error => e
    redirect_to corte_path, alert: "Google rechazó la subida: #{e.message}"
  end

  private

  def build_csv(orders)
    CSV.generate(force_quotes: true) do |csv|
      csv << [ "pedido", "fecha", "hora", "cajero", "metodo_pago", "producto", "cantidad", "precio_unitario", "modificadores_total", "notas", "modificadores", "total_linea", "total_pedido" ]
      orders.each do |order|
        order.order_items.each do |item|
          csv << [
            order.id,
            order.completed_at.to_date.iso8601,
            order.completed_at.strftime("%H:%M"),
            order.user&.name,
            order.payment_method.to_s,
            item.product.name,
            item.quantity,
            format("%.2f", item.unit_price),
            format("%.2f", item.modifiers_price),
            item.notes.to_s,
            item.modifier_lines.join(" | "),
            format("%.2f", item.line_total),
            format("%.2f", order.total)
          ]
        end
      end
    end
  end

  def csv_filename(period, date, range_start, range_end)
    stamp = Time.current.strftime("%Y%m%d-%H%M%S")
    label =
      case period
      when "week"  then "semana-#{range_start.to_date.iso8601}_a_#{range_end.to_date.iso8601}"
      when "month" then "mes-#{date.strftime("%Y-%m")}"
      else              "dia-#{date.iso8601}"
      end
    "corte-#{label}-#{stamp}.csv"
  end


  def parse_date(str)
    return nil if str.blank?
    Date.parse(str)
  rescue ArgumentError
    nil
  end

  def period_range(date, period)
    case period
    when "week"  then [date.beginning_of_week.beginning_of_day, date.end_of_week.end_of_day]
    when "month" then [date.beginning_of_month.beginning_of_day, date.end_of_month.end_of_day]
    else              [date.beginning_of_day, date.end_of_day]
    end
  end

  def navigation_dates(date, period)
    case period
    when "week"  then [date - 7, date + 7]
    when "month" then [date.prev_month, date.next_month]
    else              [date - 1, date + 1]
    end
  end

  def top_products(orders)
    tally = Hash.new { |h, k| h[k] = { name: nil, qty: 0, revenue: 0.to_d } }
    orders.each do |o|
      o.order_items.each do |it|
        tally[it.product_id][:name] = it.product.name
        tally[it.product_id][:qty]  += it.quantity
        tally[it.product_id][:revenue] += it.line_total
      end
    end
    tally.values.sort_by { |r| -r[:qty] }.first(5)
  end

  def by_kind(orders)
    tally = { "bebida" => 0.to_d, "comida" => 0.to_d, "postre" => 0.to_d }
    orders.each do |o|
      o.order_items.each do |it|
        tally[it.product.kind] ||= 0.to_d
        tally[it.product.kind] += it.line_total
      end
    end
    tally
  end

  def by_payment(orders)
    tally = Order::PAYMENT_METHODS.to_h { |m| [ m, 0.to_d ] }
    tally["sin registrar"] = 0.to_d
    orders.each do |o|
      key = o.payment_method.presence || "sin registrar"
      tally[key] ||= 0.to_d
      tally[key] += o.total
    end
    tally.reject { |_, v| v.zero? }
  end

  def daily_breakdown(orders)
    tally = Hash.new { |h, k| h[k] = { revenue: 0.to_d, orders: 0 } }
    orders.each do |o|
      day = o.completed_at.to_date
      tally[day][:revenue] += o.total
      tally[day][:orders]  += 1
    end
    tally.sort_by { |day, _| day }
  end
end
