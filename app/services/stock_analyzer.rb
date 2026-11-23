class StockAnalyzer
  WEEKDAYS = {
    1 => "lunes",
    2 => "martes",
    3 => "miércoles",
    4 => "jueves",
    5 => "viernes",
    6 => "sábado",
    0 => "domingo"
  }.freeze

  DEFAULT_WEEKS_HISTORY = 6

  def self.call(weeks: DEFAULT_WEEKS_HISTORY)
    new(weeks: weeks).call
  end

  def initialize(weeks: DEFAULT_WEEKS_HISTORY)
    @weeks = weeks
    @since = (weeks.to_i * 7).days.ago.beginning_of_day
    @coverage_days = Setting.get(:coverage_days).to_i
    @alert_pct = Setting.get(:alert_threshold_percent).to_i
  end

  def call
    consumption = compute_consumption
    ingredients = Ingredient.ordered.to_a
    rows = ingredients.map { |ing| build_row(ing, consumption[ing.id]) }

    {
      rows: rows,
      weeks: @weeks,
      since: @since,
      coverage_days: @coverage_days,
      alert_pct: @alert_pct,
      global: global_metrics(rows)
    }
  end

  private

  # => { ingredient_id => { by_weekday: {0..6 => total_consumed_decimal}, total: decimal } }
  def compute_consumption
    tally = Hash.new { |h, k| h[k] = { by_weekday: Hash.new { |hh, kk| hh[kk] = 0.to_d }, total: 0.to_d } }

    Order.completed
         .where(completed_at: @since..Time.current)
         .includes(order_items: [ :removed_ingredients, :extras, product: { product_ingredients: :ingredient } ])
         .find_each do |order|
      wday = order.completed_at.wday
      order.order_items.each do |item|
        qty = item.quantity.to_i
        next if qty <= 0

        removed_ids = item.removed_ingredients.map(&:ingredient_id).to_set
        extra_ids   = item.extras.map(&:ingredient_id).to_set

        item.product.product_ingredients.each do |pi|
          q_per = pi.quantity_per_unit.to_d
          next if q_per.zero?

          counts = if pi.default_included
            !removed_ids.include?(pi.ingredient_id)
          else
            extra_ids.include?(pi.ingredient_id)
          end
          next unless counts

          consumed = q_per * qty
          tally[pi.ingredient_id][:by_weekday][wday] += consumed
          tally[pi.ingredient_id][:total] += consumed
        end
      end
    end

    tally
  end

  def build_row(ingredient, data)
    data ||= { by_weekday: {}, total: 0.to_d }
    weeks_elapsed = [ @weeks, 1 ].max.to_f

    # Average per weekday (across the N weeks sampled)
    weekday_avg = (0..6).to_h { |wd| [ wd, (data[:by_weekday][wd].to_d / weeks_elapsed).to_f.round(3) ] }

    # Average consumption per day (over the whole period)
    avg_daily = (data[:total].to_d / (weeks_elapsed * 7)).to_f
    avg_daily_round = avg_daily.round(3)

    stock = ingredient.stock.to_d.to_f
    min   = ingredient.min_stock.to_d.to_f

    days_remaining =
      if avg_daily > 0
        (stock / avg_daily).round(1)
      end

    alert_trigger = min * (1 + @alert_pct / 100.0)
    status =
      if stock <= 0
        :out
      elsif stock < min
        :critical
      elsif stock < alert_trigger
        :low
      else
        :ok
      end

    suggested_buy_qty =
      [ (@coverage_days * avg_daily - stock), 0 ].max.round(3)

    suggested_buy_cost = (suggested_buy_qty * ingredient.cost_per_unit.to_f).round(2)

    {
      ingredient: ingredient,
      total_consumed: data[:total].to_f.round(3),
      weekday_avg: weekday_avg,
      avg_daily: avg_daily_round,
      days_remaining: days_remaining,
      status: status,
      suggested_buy_qty: suggested_buy_qty,
      suggested_buy_cost: suggested_buy_cost
    }
  end

  def global_metrics(rows)
    total_cost = rows.sum { |r| r[:suggested_buy_cost] }.round(2)
    needs_buy  = rows.count { |r| r[:suggested_buy_qty] > 0 }
    alerts     = rows.count { |r| [ :low, :critical, :out ].include?(r[:status]) }
    { total_cost: total_cost, needs_buy: needs_buy, alerts: alerts }
  end
end
