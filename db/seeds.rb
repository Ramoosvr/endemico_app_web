# Idempotent seeds: can be run multiple times safely.
# Loaded with `bin/rails db:seed`.

# ---------- MENÚ CAFÉ ----------
#
# Cada bebida define:
#   price:    precio base
#   subkind:  grupo para catálogo (cafe_negro / cafe_con_leche / frios / chai)
#   featured: aparece en main como "rápido"
#   options:  conjunto de grupos de personalización a aplicar
#
# Shapes de options (strings):
#   "leche"       → grupo "Leche" obligatorio, opciones: entera, deslactosada, deslactosada light, almendra, coco, avena, soya
#   "shots:N"     → grupo "Shots de espresso" obligatorio, default N
#   "pump"        → grupo "Pump de sabor" opcional, default "sin"
#   "pump:X"      → grupo "Pump de sabor" opcional, default X (p. ej. "caramelo")
#   "endulzante"  → grupo "Endulzante" obligatorio, default "sin"

MENU = [
  # ---- CAFÉ NEGRO ----
  { name: "Espresso",                     price:  63, subkind: "cafe_negro",     options: %w[shots:1 endulzante] },
  { name: "Espresso doble",               price:  73, subkind: "cafe_negro",     options: %w[shots:2 endulzante] },
  { name: "Americano 12 oz",              price:  75, subkind: "cafe_negro",     featured: true, options: %w[shots:2 endulzante] },
  { name: "Americano 16 oz",              price:  85, subkind: "cafe_negro",     options: %w[shots:2 endulzante] },

  # ---- CAFÉ CON LECHE ----
  { name: "Flat white",                   price:  80, subkind: "cafe_con_leche", options: %w[leche shots:2 endulzante] },
  { name: "Latte 12 oz",                  price:  95, subkind: "cafe_con_leche", featured: true, options: %w[leche shots:1 pump endulzante] },
  { name: "Latte 16 oz",                  price: 110, subkind: "cafe_con_leche", options: %w[leche shots:2 pump endulzante] },
  { name: "Capuccino 12 oz",              price:  95, subkind: "cafe_con_leche", featured: true, options: %w[leche shots:1 endulzante] },
  { name: "Capuccino italiano 6 oz",      price:  90, subkind: "cafe_con_leche", options: %w[leche shots:1 endulzante] },
  { name: "Cortado 4 oz",                 price:  83, subkind: "cafe_con_leche", options: %w[leche shots:1 endulzante] },
  { name: "Macchiato 4 oz",               price:  83, subkind: "cafe_con_leche", options: %w[leche shots:1 endulzante] },
  { name: "Caramel macchiato 12 oz",      price: 104, subkind: "cafe_con_leche", options: %w[leche shots:1 pump:caramelo endulzante] },
  { name: "Caramel macchiato 16 oz",      price: 120, subkind: "cafe_con_leche", options: %w[leche shots:2 pump:caramelo endulzante] },
  { name: "Moka 12 oz",                   price:  95, subkind: "cafe_con_leche", options: %w[leche shots:1 endulzante] },
  { name: "Moka 16 oz",                   price: 110, subkind: "cafe_con_leche", options: %w[leche shots:2 endulzante] },

  # ---- FRÍOS ----
  { name: "Iced americano 16 oz",         price:  85, subkind: "frios",          options: %w[shots:2 endulzante] },
  { name: "Iced latte 16 oz",             price: 100, subkind: "frios",          featured: true, options: %w[leche shots:2 pump endulzante] },
  { name: "Iced caramel macchiato 16 oz", price: 130, subkind: "frios",          options: %w[leche shots:2 pump:caramelo endulzante] },
  { name: "Espresso tonic 16 oz",         price: 100, subkind: "frios",          options: %w[shots:2 endulzante] },

  # ---- CHAI ----
  { name: "Chai vainilla 12 oz",          price: 110, subkind: "chai",           options: %w[leche endulzante] },
  { name: "Chai latte vainilla 16 oz",    price: 125, subkind: "chai",           options: %w[leche endulzante] },
  { name: "Chai helado vainilla 16 oz",   price: 115, subkind: "chai",           options: %w[leche endulzante] },
  { name: "Dirty chai 12 oz",             price: 145, subkind: "chai",           options: %w[leche shots:1 endulzante] },
  { name: "Dirty chai 16 oz",             price: 165, subkind: "chai",           options: %w[leche shots:2 endulzante] }
].freeze

# ---------- OPTION GROUPS ----------
MILK_CHOICES      = [ "Entera", "Deslactosada", "Deslactosada light", "Almendra", "Coco", "Avena", "Soya" ].freeze
SHOTS_CHOICES     = %w[1 2 3].freeze
PUMP_CHOICES      = [ "Sin pump", "Normal", "Vainilla", "Vainilla light", "Vainilla francesa", "Caramelo", "Coco", "Banana" ].freeze
SWEETENER_CHOICES = [ "Sin endulzante", "Azúcar", "Splenda", "Stevia" ].freeze

def upsert_option_group(product, name:, required:, mode: "single", position:, choices:, default:)
  group = product.option_groups.find_or_initialize_by(name: name)
  group.required       = required
  group.selection_mode = mode
  group.position       = position
  group.save!

  choices.each_with_index do |choice_name, idx|
    oc = group.option_choices.find_or_initialize_by(name: choice_name)
    oc.extra_price      = 0
    oc.position         = idx
    oc.default_selected = (choice_name == default)
    oc.save!
  end

  # remove any stale choices not in list
  group.option_choices.where.not(name: choices).destroy_all
end

def apply_options(product, tokens)
  position = 0
  tokens.each do |token|
    case token
    when "leche"
      upsert_option_group(product,
        name: "Leche", required: true, position: (position += 1),
        choices: MILK_CHOICES, default: "Entera")
    when /\Ashots:(\d+)\z/
      default = Regexp.last_match(1)
      upsert_option_group(product,
        name: "Shots de espresso", required: true, position: (position += 1),
        choices: SHOTS_CHOICES, default: default)
    when "pump"
      upsert_option_group(product,
        name: "Pump de sabor", required: false, position: (position += 1),
        choices: PUMP_CHOICES, default: "Sin pump")
    when /\Apump:(.+)\z/
      default = Regexp.last_match(1).capitalize
      upsert_option_group(product,
        name: "Pump de sabor", required: false, position: (position += 1),
        choices: PUMP_CHOICES, default: default)
    when "endulzante"
      upsert_option_group(product,
        name: "Endulzante", required: true, position: (position += 1),
        choices: SWEETENER_CHOICES, default: "Sin endulzante")
    end
  end

  # remove any option groups not in this list of token names
  expected_names = tokens.map do |t|
    case t
    when "leche"           then "Leche"
    when /\Ashots:/        then "Shots de espresso"
    when "pump", /\Apump:/ then "Pump de sabor"
    when "endulzante"      then "Endulzante"
    end
  end.compact
  product.option_groups.where.not(name: expected_names).destroy_all
end

# ---------- EXTRAS (ingredientes opcionales que suman al precio) ----------
# Regla: todas las bebidas pueden agregar extras. Los extras y precios por default:
EXTRAS_BY_SUBKIND = {
  "cafe_negro" => [
    { name: "Shot extra de espresso", price: 15 },
    { name: "Hielo",                  price:  0 }
  ],
  "cafe_con_leche" => [
    { name: "Shot extra de espresso", price: 15 },
    { name: "Pump de sabor extra",    price: 10 },
    { name: "Crema batida",           price: 15 },
    { name: "Canela",                 price:  0 },
    { name: "Hielo",                  price:  0 }
  ],
  "frios" => [
    { name: "Shot extra de espresso", price: 15 },
    { name: "Pump de sabor extra",    price: 10 },
    { name: "Crema batida",           price: 15 },
    { name: "Hielo extra",            price:  0 }
  ],
  "chai" => [
    { name: "Shot extra de espresso", price: 15 },
    { name: "Crema batida",           price: 15 },
    { name: "Canela",                 price:  0 },
    { name: "Hielo",                  price:  0 }
  ]
}.freeze

def apply_extras(product)
  list = EXTRAS_BY_SUBKIND[product.subkind.to_s] || []
  list.each_with_index do |e, idx|
    ing = Ingredient.find_or_create_by!(name: e[:name]) { |i| i.unit = "pza" }
    pi  = product.product_ingredients.find_or_initialize_by(ingredient_id: ing.id)
    pi.default_included = false
    pi.extra_price      = e[:price]
    pi.position         = 100 + idx   # separate from default ingredients
    pi.quantity_per_unit = 0
    pi.save!
  end

  # Clean up extras no longer in the list (keep defaults untouched).
  keep_names = list.map { |e| e[:name] }
  product.product_ingredients.joins(:ingredient)
         .where(default_included: false)
         .where.not(ingredients: { name: keep_names })
         .destroy_all
end

# ---------- INSUMOS DE PRESENTACIÓN (vasos, tapas, sleeve, popote) ----------
# Se descuentan del stock cada vez que se cobra una bebida.
# Precios y stock iniciales son estimados — ajusta en /insumos.
CUPS_CATALOG = {
  "Vaso 4 oz"            => { unit: "pza", cost: 1.80, min_stock: 100 },
  "Vaso 6 oz"            => { unit: "pza", cost: 2.50, min_stock: 100 },
  "Vaso 12 oz"           => { unit: "pza", cost: 3.50, min_stock: 100 },
  "Vaso 16 oz"           => { unit: "pza", cost: 4.00, min_stock: 100 },
  "Vaso frío 16 oz"      => { unit: "pza", cost: 4.50, min_stock: 100 },
  "Tapa chica"           => { unit: "pza", cost: 1.00, min_stock: 100 },
  "Tapa caliente 12/16"  => { unit: "pza", cost: 1.20, min_stock: 100 },
  "Tapa cúpula fría"     => { unit: "pza", cost: 1.50, min_stock: 100 },
  "Sleeve cartón"        => { unit: "pza", cost: 1.00, min_stock: 100 },
  "Popote"               => { unit: "pza", cost: 0.50, min_stock: 100 }
}.freeze

def cups_for(name)
  cold = name.match?(/iced|helado|tonic|frío/i)
  return [ "Vaso frío 16 oz", "Tapa cúpula fría", "Popote" ]          if cold
  return [ "Vaso 16 oz",      "Tapa caliente 12/16", "Sleeve cartón" ] if name.match?(/16 oz/i)
  return [ "Vaso 12 oz",      "Tapa caliente 12/16", "Sleeve cartón" ] if name.match?(/12 oz/i)
  return [ "Vaso 6 oz",       "Tapa chica" ]                           if name.match?(/6 oz|flat white/i)
  return [ "Vaso 4 oz",       "Tapa chica" ]                           if name.match?(/4 oz|espresso/i)
  []
end

def apply_cups(product)
  needed = cups_for(product.name)
  needed.each_with_index do |ing_name, idx|
    cfg = CUPS_CATALOG[ing_name] || { unit: "pza", cost: 0, min_stock: 100 }
    ing = Ingredient.find_or_create_by!(name: ing_name) do |i|
      i.unit          = cfg[:unit]
      i.cost_per_unit = cfg[:cost]
      i.min_stock     = cfg[:min_stock]
      i.stock         = 500   # inicial estimado — ajusta en /insumos
    end
    pi = product.product_ingredients.find_or_initialize_by(ingredient_id: ing.id)
    pi.default_included  = true
    pi.quantity_per_unit = 1
    pi.extra_price       = 0
    pi.position          = 50 + idx
    pi.save!
  end

  # Cleanup: borra PIs default a insumos del CUPS_CATALOG que ya no apliquen a este producto.
  product.product_ingredients.joins(:ingredient)
         .where(default_included: true)
         .where(ingredients: { name: CUPS_CATALOG.keys })
         .where.not(ingredients: { name: needed })
         .destroy_all
end

MENU.each do |item|
  product = Product.find_or_initialize_by(name: item[:name])
  product.kind     = "bebida"
  product.subkind  = item[:subkind]
  product.featured = item[:featured] == true
  product.price    = item[:price]
  product.stock    = 999 if product.stock.to_i.zero?
  product.save!

  apply_options(product, item[:options])
  apply_extras(product)
  apply_cups(product)

  # Auto-costear desde insumos default si el admin aún no editó cost a mano.
  if product.cost.to_f.zero?
    material = product.product_ingredients.includes(:ingredient)
                                          .where(default_included: true)
                                          .sum { |pi| pi.quantity_per_unit.to_d * pi.ingredient.cost_per_unit.to_d }
    product.update!(cost: material) if material.positive?
  end
end

extras_count = ProductIngredient.joins(:product).where(default_included: false, products: { kind: "bebida" }).count
cups_count   = ProductIngredient.joins(:product, :ingredient)
                                .where(default_included: true, products: { kind: "bebida" }, ingredients: { name: CUPS_CATALOG.keys })
                                .count
puts "Seeds OK: #{Product.where(name: MENU.map { |i| i[:name] }).count}/#{MENU.size} bebidas · " \
     "#{Product.featured.count} featured · " \
     "#{OptionGroup.joins(:product).where(products: { kind: 'bebida' }).count} grupos · " \
     "#{extras_count} extras · " \
     "#{cups_count} links vaso/tapa."
