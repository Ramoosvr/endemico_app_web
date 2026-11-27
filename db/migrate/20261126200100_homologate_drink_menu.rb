# Rebuilds the drinks menu the way the café asked for it (Nov 2026):
#
# - One button per drink with a 12/16 oz size picker (Americano, Latte,
#   Caramel macchiato, Moka, Chai latte, Dirty chai). The old "12 oz" and
#   "16 oz" products are hidden, not deleted, so past sales keep their names.
# - Every chai (hot and iced) asks Vainilla or Especias.
# - Cold drinks live in "Fríos" and are all 16 oz. "Chai helado" becomes
#   "Iced Chai"; Iced dirty chai, Iced moka, Cold Brew and Long black are new.
# - No more "Temperatura", "Shots de espresso" or "Pump de sabor" groups.
#   Sweeteners gain "Mascabado". Extras are counters: shot $30, syrup pump
#   $10 (with flavor). Lattes add an optional "Sabor" (+$15).
# - Sodas and Ciau have no extras; Ciau moves to Refrescos.
#
# Prices come from the "Mis precios" column of the Recetario sheet, except
# Dirty chai, which keeps its current $145 / $165 for now.
# Products are looked up by name; anything missing is skipped, so the
# migration is safe to run on a database that differs a little.
class HomologateDrinkMenu < ActiveRecord::Migration[8.1]
  class Ingredient < ActiveRecord::Base
    self.table_name = "ingredients"
  end

  class OptionChoiceIngredient < ActiveRecord::Base
    self.table_name = "option_choice_ingredients"
  end

  class OrderItemOptionChoice < ActiveRecord::Base
    self.table_name = "order_item_option_choices"
  end

  class OptionChoice < ActiveRecord::Base
    self.table_name = "option_choices"
    has_many :option_choice_ingredients, class_name: "HomologateDrinkMenu::OptionChoiceIngredient", dependent: :delete_all
  end

  class OptionGroup < ActiveRecord::Base
    self.table_name = "option_groups"
    has_many :option_choices, -> { order(:position, :id) }, class_name: "HomologateDrinkMenu::OptionChoice", dependent: :destroy
  end

  class ProductIngredient < ActiveRecord::Base
    self.table_name = "product_ingredients"
  end

  class Product < ActiveRecord::Base
    self.table_name = "products"
    has_many :option_groups, -> { where(active: true).order(:position, :id) }, class_name: "HomologateDrinkMenu::OptionGroup"
    has_many :product_ingredients, class_name: "HomologateDrinkMenu::ProductIngredient"
  end

  SWEETENERS   = [ "Sin endulzante", "Azúcar", "Splenda", "Stevia", "Mascabado" ].freeze
  PUMP_FLAVORS = [ "Vainilla", "Vainilla sugar free", "Caramelo", "Caramelo sugar free", "Banana", "Coco" ].freeze
  CHAI_FLAVORS = [ "Vainilla", "Especias" ].freeze

  SHOT_PRICE         = 30
  PUMP_PRICE         = 10
  LATTE_FLAVOR_PRICE = 15

  SHOT_GROUP   = "Shot extra de espresso".freeze
  PUMP_GROUP   = "Pump de jarabe extra".freeze
  REMOVED_GROUPS = [ "Temperatura", "Shots de espresso", "Pump de sabor" ].freeze
  REMOVED_EXTRAS = [ "Hielo", "Shot extra de espresso", "Pump de sabor extra" ].freeze

  HOT_CUP_12 = [ "Vaso cartón 12 oz", "Tapa negra", "Manga de cartón" ].freeze
  HOT_CUP_16 = [ "Vaso cartón 16 oz", "Tapa negra", "Manga de cartón" ].freeze

  # name, subkind, 12 oz price, 16 oz price, products it replaces, chai?
  SIZED = [
    [ "Americano",         "cafe_negro",     75,  85,  [ "Americano 12 oz", "Americano 16 oz" ], false ],
    [ "Latte",             "cafe_con_leche", 95,  110, [ "Latte 12 oz", "Latte 16 oz" ], false ],
    [ "Caramel macchiato", "cafe_con_leche", 104, 120, [ "Caramel macchiato 12 oz", "Caramel macchiato 16 oz" ], false ],
    [ "Moka",              "cafe_con_leche", 95,  110, [ "Moka 12 oz", "Moka 16 oz" ], false ],
    [ "Chai latte",        "chai_caliente",  110, 125, [ "Chai vainilla 12 oz", "Chai latte vainilla 16 oz" ], true ],
    [ "Dirty chai",        "chai_caliente",  145, 165, [ "Dirty chai 12 oz", "Dirty chai 16 oz" ], true ]
  ].freeze

  SINGLE_PRICES = {
    "Espresso"                     => 63,
    "Espresso doble"               => 73,
    "Capuccino 12 oz"              => 95,
    "Capuccino italiano 6 oz"      => 90,
    "Cortado 4 oz"                 => 83,
    "Macchiato 4 oz"               => 83,
    "Flat white"                   => 80,
    "Iced americano 16 oz"         => 85,
    "Iced latte 16 oz"             => 100,
    "Iced caramel macchiato 16 oz" => 130,
    "Espresso tonic 16 oz"         => 100
  }.freeze

  # Single-size hot drinks that used to take their cup from "Temperatura".
  HOT_CUP_DEFAULTS = [ "Capuccino 12 oz", "Flat white" ].freeze

  # name, subkind, price, copy Leche from, chai?
  NEW_DRINKS = [
    [ "Long black 12 oz",      "cafe_negro", 85,  nil,                false ],
    [ "Cold Brew",             "frios",      90,  nil,                false ],
    [ "Iced dirty chai 16 oz", "frios",      135, "Dirty chai 12 oz", true ],
    [ "Iced moka 16 oz",       "frios",      115, "Moka 12 oz",       false ]
  ].freeze

  LATTES = [ "Latte", "Iced latte 16 oz" ].freeze
  NO_EXTRAS = [ "Agua", "Coca", "Coca light", "Ciau" ].freeze

  def up
    [ Product, OptionGroup, OptionChoice, ProductIngredient ].each(&:reset_column_information)

    transaction do
      build_sized_drinks
      update_single_drinks
      build_iced_chai
      build_new_drinks
      LATTES.each { |name| add_latte_flavor(find_product(name)) }
      clean_sodas
      homologate_all_drinks
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Restore the drinks menu from a database backup."
  end

  private

  def find_product(name)
    Product.where("LOWER(name) = ?", name.downcase).order(:id).first
  end

  def find_ingredient(name)
    Ingredient.where("LOWER(name) = ?", name.downcase).first
  end

  # --- 12/16 oz drinks -------------------------------------------------------

  def build_sized_drinks
    SIZED.each do |name, subkind, price12, price16, old_names, chai|
      olds = old_names.filter_map { |n| find_product(n) }
      next if olds.empty? && find_product(name).nil?

      product = find_product(name) || Product.create!(
        name: name, kind: "bebida", subkind: subkind,
        price: price12, cost: olds.first&.cost || 0,
        stock: olds.map(&:stock).max || 999,
        featured: true, active: true
      )
      product.update!(subkind: subkind, price: price12, featured: true, active: true)

      size = ensure_group(product, "Tamaño", mode: "single", required: true)
      ensure_choice(size, "12 oz", 0, default: true, position: 0, cups: HOT_CUP_12)
      ensure_choice(size, "16 oz", price16 - price12, position: 1, cups: HOT_CUP_16)

      add_chai_flavor(product) if chai
      copy_group(olds.first, product, "Leche") if olds.first

      olds.each { |old| old.update!(active: false, featured: false) }
    end
  end

  def update_single_drinks
    SINGLE_PRICES.each do |name, price|
      find_product(name)&.update!(price: price)
    end

    HOT_CUP_DEFAULTS.each do |name|
      product = find_product(name) or next
      add_cup_defaults(product, HOT_CUP_12)
    end
  end

  def build_iced_chai
    product = find_product("Iced Chai") || find_product("Chai helado vainilla 16 oz")
    return unless product

    product.update!(name: "Iced Chai", subkind: "frios", price: 115, featured: true, active: true)
    add_chai_flavor(product)
  end

  def build_new_drinks
    NEW_DRINKS.each do |name, subkind, price, leche_from, chai|
      product = find_product(name) || Product.create!(
        name: name, kind: "bebida", subkind: subkind, price: price,
        cost: 0, stock: 999, featured: true, active: true
      )
      product.update!(subkind: subkind, price: price, featured: true, active: true)

      add_chai_flavor(product) if chai
      source = leche_from && find_product(leche_from)
      copy_group(source, product, "Leche") if source
      add_cup_defaults(product, HOT_CUP_12) if subkind == "cafe_negro"
    end
  end

  def add_chai_flavor(product)
    group = ensure_group(product, "Sabor", mode: "single", required: true)
    CHAI_FLAVORS.each_with_index do |flavor, i|
      ensure_choice(group, flavor, 0, default: i.zero?, position: i)
    end
  end

  def add_latte_flavor(product)
    return unless product

    group = ensure_group(product, "Sabor", mode: "single", required: false)
    PUMP_FLAVORS.each_with_index do |flavor, i|
      ensure_choice(group, flavor, LATTE_FLAVOR_PRICE, position: i)
    end
  end

  # --- Sodas -----------------------------------------------------------------

  def clean_sodas
    NO_EXTRAS.each do |name|
      product = find_product(name) or next
      product.product_ingredients.where(default_included: false).delete_all
      product.option_groups.each { |og| retire_group(og) }
    end
    find_product("Ciau")&.update!(subkind: "refrescos")
  end

  # --- Every drink -----------------------------------------------------------

  def homologate_all_drinks
    removed_extra_ids = REMOVED_EXTRAS.filter_map { |n| find_ingredient(n)&.id }

    Product.where(kind: "bebida", active: true).where.not(subkind: "refrescos").find_each do |product|
      product.option_groups.where(name: REMOVED_GROUPS).each { |og| retire_group(og) }
      product.product_ingredients.where(default_included: false, ingredient_id: removed_extra_ids).delete_all

      sweet = ensure_group(product, "Endulzante", mode: "single", required: true)
      has_default = sweet.option_choices.where(default_selected: true).exists?
      SWEETENERS.each_with_index do |name, i|
        ensure_choice(sweet, name, 0, default: i.zero? && !has_default, position: i)
      end

      shot = ensure_group(product, SHOT_GROUP, mode: "counter", required: false)
      ensure_choice(shot, SHOT_GROUP, SHOT_PRICE, position: 0)

      pump = ensure_group(product, PUMP_GROUP, mode: "counter", required: false)
      PUMP_FLAVORS.each_with_index { |flavor, i| ensure_choice(pump, flavor, PUMP_PRICE, position: i) }

      order_groups(product)
    end
  end

  GROUP_ORDER = [ "Tamaño", "Sabor", "Leche", "Endulzante", SHOT_GROUP, PUMP_GROUP ].freeze

  def order_groups(product)
    product.option_groups.reload.each do |og|
      rank = GROUP_ORDER.index(og.name) || GROUP_ORDER.size
      # The optional latte "Sabor" sits with the extras, after the sweetener.
      rank = GROUP_ORDER.index(SHOT_GROUP) - 0.5 if og.name == "Sabor" && !og.required
      og.update_columns(position: (rank * 10).to_i)
    end
  end

  # --- Helpers ---------------------------------------------------------------

  def ensure_group(product, name, mode:, required:)
    group = product.option_groups.find_by(name: name) ||
            OptionGroup.create!(product_id: product.id, name: name, active: true,
                                selection_mode: mode, required: required, position: 0)
    group.update!(selection_mode: mode, required: required)
    group
  end

  def ensure_choice(group, name, price, position:, default: false, cups: [])
    choice = group.option_choices.find_by(name: name) ||
             OptionChoice.create!(option_group_id: group.id, name: name, extra_price: price,
                                  default_selected: default, position: position)
    choice.update!(extra_price: price, position: position, default_selected: default || choice.default_selected)

    cups.each do |ingredient_name|
      ingredient = find_ingredient(ingredient_name) or next
      next if OptionChoiceIngredient.exists?(option_choice_id: choice.id, ingredient_id: ingredient.id)

      OptionChoiceIngredient.create!(option_choice_id: choice.id, ingredient_id: ingredient.id, quantity_per_unit: 1)
    end
    choice
  end

  def copy_group(source, target, name)
    return if target.option_groups.exists?(name: name)

    group = source.option_groups.find_by(name: name) or return
    copy = OptionGroup.create!(product_id: target.id, name: group.name, active: true,
                               selection_mode: group.selection_mode, required: group.required,
                               position: group.position)
    group.option_choices.each do |choice|
      new_choice = OptionChoice.create!(option_group_id: copy.id, name: choice.name,
                                        extra_price: choice.extra_price,
                                        default_selected: choice.default_selected,
                                        position: choice.position)
      choice.option_choice_ingredients.each do |oci|
        OptionChoiceIngredient.create!(option_choice_id: new_choice.id, ingredient_id: oci.ingredient_id,
                                       quantity_per_unit: oci.quantity_per_unit)
      end
    end
  end

  def add_cup_defaults(product, names)
    names.each_with_index do |ingredient_name, i|
      ingredient = find_ingredient(ingredient_name) or next
      next if product.product_ingredients.exists?(ingredient_id: ingredient.id)

      ProductIngredient.create!(product_id: product.id, ingredient_id: ingredient.id,
                                default_included: true, extra_price: 0,
                                quantity_per_unit: 1, position: 100 + i)
    end
  end

  # Delete a group, or hide it when past sales point to its choices.
  def retire_group(group)
    used = OrderItemOptionChoice.where(option_choice_id: group.option_choices.select(:id)).exists?
    if used
      group.update!(active: false)
    else
      group.destroy!
    end
  end
end
