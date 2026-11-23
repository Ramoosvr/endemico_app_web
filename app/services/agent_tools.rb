module AgentTools
  module_function

  def definitions
    [
      {
        name: "get_ingredients",
        description: "Devuelve el catálogo completo de insumos con stock actual, mínimo, precio por unidad, proveedor y estado (debajo del mínimo).",
        input_schema: {
          type: "object",
          properties: {},
          required: []
        }
      },
      {
        name: "get_stock_analysis",
        description: "Corre el analizador de stock: consumo promedio diario, consumo por día de semana (lunes a domingo), días restantes por insumo al ritmo actual, y lista de compra sugerida para cubrir N días. Úsalo para decidir qué comprar y cuándo.",
        input_schema: {
          type: "object",
          properties: {
            weeks: {
              type: "integer",
              description: "Cuántas semanas hacia atrás usar para calcular promedios. Default 6, max 26.",
              minimum: 1,
              maximum: 26
            }
          },
          required: []
        }
      },
      {
        name: "get_sales_summary",
        description: "Resumen de ventas agregadas: total facturado, pedidos, productos vendidos. Permite agrupar por período.",
        input_schema: {
          type: "object",
          properties: {
            period: {
              type: "string",
              enum: [ "day", "week", "month" ],
              description: "Agrupamiento del período."
            },
            date: {
              type: "string",
              description: "Fecha de referencia en formato YYYY-MM-DD. Default: hoy."
            }
          },
          required: [ "period" ]
        }
      },
      {
        name: "get_recent_orders",
        description: "Lista los últimos pedidos cobrados con sus artículos, cantidades y totales. Útil para revisar qué se está vendiendo últimamente.",
        input_schema: {
          type: "object",
          properties: {
            limit: { type: "integer", description: "Cuántos pedidos. Default 10, max 50.", minimum: 1, maximum: 50 }
          },
          required: []
        }
      },
      {
        name: "get_settings",
        description: "Devuelve la configuración operativa actual: días de cobertura, día de compra, umbral de alerta, datos del proveedor. Úsala si necesitas saber bajo qué reglas opera el negocio.",
        input_schema: { type: "object", properties: {}, required: [] }
      }
    ]
  end

  def run(name, args)
    case name
    when "get_ingredients"     then get_ingredients
    when "get_stock_analysis"  then get_stock_analysis(args)
    when "get_sales_summary"   then get_sales_summary(args)
    when "get_recent_orders"   then get_recent_orders(args)
    when "get_settings"        then get_settings
    else { error: "Herramienta desconocida: #{name}" }
    end
  rescue => e
    { error: e.message, error_class: e.class.name }
  end

  def get_ingredients
    ings = Ingredient.ordered.map do |ing|
      {
        id: ing.id,
        name: ing.name,
        unit: ing.unit,
        stock: ing.stock.to_f,
        min_stock: ing.min_stock.to_f,
        cost_per_unit: ing.cost_per_unit.to_f,
        supplier: ing.supplier,
        below_min: ing.below_min?
      }
    end
    { count: ings.size, ingredients: ings }
  end

  def get_stock_analysis(args)
    weeks = (args["weeks"] || 6).to_i.clamp(1, 26)
    result = StockAnalyzer.call(weeks: weeks)
    rows = result[:rows].map do |r|
      ing = r[:ingredient]
      {
        ingredient: ing.name,
        unit: ing.unit,
        stock: ing.stock.to_f,
        min_stock: ing.min_stock.to_f,
        total_consumed: r[:total_consumed],
        avg_daily: r[:avg_daily],
        weekday_avg: r[:weekday_avg].transform_keys { |k| StockAnalyzer::WEEKDAYS[k] },
        days_remaining: r[:days_remaining],
        status: r[:status],
        suggested_buy_qty: r[:suggested_buy_qty],
        suggested_buy_cost: r[:suggested_buy_cost]
      }
    end
    {
      weeks_analyzed: result[:weeks],
      coverage_days_target: result[:coverage_days],
      total_shopping_cost: result[:global][:total_cost],
      ingredients_to_buy: result[:global][:needs_buy],
      ingredients_in_alert: result[:global][:alerts],
      rows: rows
    }
  end

  def get_sales_summary(args)
    period = args["period"] || "day"
    date   = (Date.parse(args["date"]) rescue Date.current)
    range  = case period
             when "week"  then date.beginning_of_week.beginning_of_day..date.end_of_week.end_of_day
             when "month" then date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
             else              date.beginning_of_day..date.end_of_day
             end

    orders = Order.completed.where(completed_at: range).includes(order_items: :product)

    top = Hash.new { |h, k| h[k] = { name: nil, qty: 0, revenue: 0.to_d } }
    kinds = Hash.new(0.to_d)
    total_items = 0

    orders.each do |o|
      o.order_items.each do |it|
        top[it.product_id][:name] = it.product.name
        top[it.product_id][:qty]  += it.quantity
        top[it.product_id][:revenue] += it.line_total
        kinds[it.product.kind] += it.line_total
        total_items += it.quantity.to_i
      end
    end

    {
      period: period,
      range_from: range.first.iso8601,
      range_to:   range.last.iso8601,
      orders: orders.size,
      total_revenue: orders.sum(&:total).to_f,
      total_items: total_items,
      revenue_by_kind: kinds.transform_values(&:to_f),
      top_products: top.values.sort_by { |r| -r[:qty] }.first(10).map { |r| r.merge(revenue: r[:revenue].to_f) }
    }
  end

  def get_recent_orders(args)
    limit = (args["limit"] || 10).to_i.clamp(1, 50)
    orders = Order.completed.order(completed_at: :desc).limit(limit).includes(:user, order_items: :product)
    {
      count: orders.size,
      orders: orders.map do |o|
        {
          id: o.id,
          at: o.completed_at.iso8601,
          cashier: o.user&.name,
          total: o.total.to_f,
          items: o.order_items.map { |it| { product: it.product.name, qty: it.quantity, line_total: it.line_total.to_f } }
        }
      end
    }
  end

  def get_settings
    s = Setting.all_with_defaults
    {
      coverage_days: s["coverage_days"].to_i,
      purchase_day: s["purchase_day"],
      alert_threshold_percent: s["alert_threshold_percent"].to_i,
      supplier_name: s["supplier_name"],
      supplier_whatsapp_configured: s["supplier_whatsapp"].to_s.present?,
      ai_model: s["ai_model"]
    }
  end
end
