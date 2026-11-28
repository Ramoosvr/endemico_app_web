module Matriz
  # Applies what the Apps Script in the "Matriz" sheet sends, and answers with
  # the POS stock so the sheet can mirror it. Every part is validated; a bad
  # row is reported and skipped, never applied half-way, and never stops sales.
  #
  # Payload (all keys optional):
  #   inventario: [{ cod, articulo, marca, cantidad, unidad, paquete, precio,
  #                  precio_unitario, stock, stock_unidad, donde_comprar,
  #                  minimo, seccion, seccion_pos, pos }]
  #   recetas:    [{ producto, tamano, insumo, cantidad, elegido_en }]
  #   opciones:   [{ producto, grupo, opcion, insumo, cantidad }]
  #   conteos:    [{ cod, stock }]   # STOCK typed by hand in the sheet
  #   recetario + equivalencias: raw grids of those tabs, sent only after
  #               someone presses "Actualizar recetas" in the POS.
  class Sync
    REQUEST_KEY = "matriz_recetas_pedidas_at".freeze
    RESULT_KEY  = "matriz_recetas_resultado".freeze

    def self.request_recipes!
      Setting.set(REQUEST_KEY, Time.current.iso8601)
    end

    def self.recipes_requested?
      Setting.find_by(key: REQUEST_KEY)&.value.present?
    end

    def self.last_recipe_result
      raw = Setting.find_by(key: RESULT_KEY)&.value
      raw.present? ? JSON.parse(raw) : nil
    rescue JSON::ParserError
      nil
    end

    UNIT_MAP = {
      "gr" => "g", "g" => "g", "grs" => "g", "gramos" => "g",
      "kg" => "kg", "ml" => "ml", "l" => "l", "lt" => "l", "litro" => "l",
      "pza" => "pza", "pieza" => "pza", "piezas" => "pza", "pzas" => "pza", "paquete" => "pza"
    }.freeze
    # A sheet read that comes back with fewer rows than this is treated as
    # broken: nothing is archived.
    MIN_ROWS_TO_ARCHIVE = 20
    TODAS = %w[todas todos * ""].freeze

    attr_reader :errors, :notes

    def initialize(payload, user: nil)
      @payload = payload.to_h.deep_stringify_keys
      @user = user
      @errors = []
      @notes = []
    end

    def call
      sync_inventory if @payload["inventario"].present?
      apply_counts   if @payload["conteos"].present?
      sync_recetario if @payload["recetario"].present?
      sync_recipes   if @payload["recetas"].present?
      sync_options   if @payload["opciones"].present?
      self
    end

    def response
      {
        ok: errors.empty?,
        errores: errors,
        avisos: notes,
        stock: Ingredient.active.where.not(external_id: nil).map { |i| { cod: i.external_id, stock: i.stock.to_f } },
        nuevos: pos_only_ingredients.map { |i| serialize_new(i) },
        pedir_recetas: self.class.recipes_requested?,
        hora: Time.current.iso8601
      }
    end

    private

    # ---------- Inventario ----------

    def sync_inventory
      rows = Array(@payload["inventario"]).map { |r| r.to_h }
      seen = []
      rows.each_with_index do |row, idx|
        cod  = row["cod"].to_s.strip
        name = row["articulo"].to_s.strip
        next if name.blank?
        if cod.blank?
          errors << "Inventario: \"#{name}\" no tiene COD."
          next
        end

        ing = Ingredient.find_by(external_id: cod) ||
              Ingredient.where(external_id: nil).find_by("LOWER(name) = ?", name.downcase) ||
              Ingredient.archived.find_by("LOWER(name) = ?", name.downcase) ||
              Ingredient.new(external_id: cod)
        clash = Ingredient.where.not(id: ing.id).find_by("LOWER(name) = ?", name.downcase)
        if clash && !clash.archived?
          errors << "Inventario: el nombre \"#{name}\" está repetido (#{cod} y #{clash.external_id})."
          next
        elsif clash
          clash.update_columns(name: "#{clash.name} (archivado #{clash.id})")
        end

        first_time = ing.new_record? || !ing.inventory_movements.exists?
        ing.assign_attributes(
          external_id: cod,
          name: name,
          brand: row["marca"].to_s.strip.presence,
          unit: unit_for(row["stock_unidad"].presence || row["unidad"]),
          package_size: number(row["cantidad"]),
          package_unit: row["unidad"].to_s.strip.presence,
          package_count: number(row["paquete"]),
          package_price: number(row["precio"]),
          unit_cost: number(row["precio_unitario"]),
          cost_per_unit: (number(row["precio_unitario"]) || 0).round(2),
          supplier: row["donde_comprar"].to_s.strip.presence,
          section: row["seccion"].to_s.strip.presence,
          section_position: row["seccion_pos"].to_i,
          position: row["pos"].presence&.to_i || idx,
          archived_at: nil
        )
        ing.min_stock = number(row["minimo"]) if row.key?("minimo") && number(row["minimo"])
        ing.category ||= "otros"

        Ingredient.transaction do
          ing.save!
          if first_time
            initial = number(row["stock"]) || 0
            delta = initial - ing.stock.to_d
            ing.apply_movement!(delta, kind: "carga_inicial", user: @user,
                                note: "Stock inicial tomado de Matriz: #{initial}")
          end
        end
        seen << ing.id
      rescue ActiveRecord::RecordInvalid => e
        errors << "Inventario: \"#{name}\": #{e.record.errors.full_messages.to_sentence}."
      end

      archive_missing(seen) if rows.size >= MIN_ROWS_TO_ARCHIVE
    end

    # Ingredients that are not in the sheet: the old POS catalog. They are
    # archived (hidden), never deleted. Ingredients created in the POS
    # ("POS-..") are kept until the sheet adds them.
    def archive_missing(seen_ids)
      scope = Ingredient.active.where.not(id: seen_ids)
                        .where("external_id IS NULL OR external_id NOT LIKE 'POS-%'")
      count = scope.count
      return if count.zero?
      scope.update_all(archived_at: Time.current)
      notes << "#{count} insumos viejos del POS quedaron archivados (no se borran)."
    end

    def apply_counts
      Array(@payload["conteos"]).each do |row|
        cod = row["cod"].to_s.strip
        value = number(row["stock"])
        ing = Ingredient.active.find_by(external_id: cod)
        if ing.nil? || value.nil?
          errors << "Conteo: no se pudo aplicar #{cod.presence || "(sin COD)"} = #{row["stock"]}."
          next
        end
        delta = value - ing.stock.to_d
        next if delta.zero?
        ing.apply_movement!(delta, kind: "ajuste", user: @user, note: "Conteo escrito en Matriz: #{value}")
      end
    end

    # ---------- Recetario (cards) ----------

    def sync_recetario
      before = errors.size
      parser = RecetarioParser.new(@payload["recetario"], @payload["equivalencias"]).call
      errors.concat(parser.errors)
      notes.concat(parser.notes)
      @payload["recetas"] = parser.recipes
      @payload["opciones"] = parser.options if parser.options.any?
      sync_recipes if parser.recipes.any?
      sync_options if parser.options.any?
      Setting.find_by(key: REQUEST_KEY)&.destroy
      Setting.set(RESULT_KEY, {
        at: Time.current.iso8601,
        recetas: RecipeLine.distinct.count(:product_id),
        errores: errors.drop(before),
        avisos: notes
      }.to_json)
      @payload.delete("recetas")
      @payload.delete("opciones")
    end

    # ---------- Recetas ----------

    def sync_recipes
      rows = Array(@payload["recetas"]).map(&:to_h).reject { |r| r["producto"].to_s.strip.blank? }
      by_product = rows.group_by { |r| r["producto"].to_s.strip.downcase }
      touched = []

      by_product.each_value do |lines|
        label = lines.first["producto"].to_s.strip
        product = find_product(label)
        unless product
          notes << "Recetario: \"#{label}\" no es un producto del POS, se ignora."
          next
        end
        touched << product.id

        problems = []
        built = lines.each_with_index.map do |r, i|
          ing = find_ingredient(r["insumo"])
          qty = number(r["cantidad"])
          size = r["tamano"].to_s.strip.presence
          slot = r["elegido_en"].to_s.strip.presence
          problems << "insumo \"#{r["insumo"]}\" no existe" unless ing
          problems << "cantidad \"#{r["cantidad"]}\" de #{r["insumo"]} no es válida" unless qty&.positive?
          problems << "tamaño \"#{size}\" no existe" if size && !product_sizes(product).include?(size.downcase)
          problems << "grupo \"#{slot}\" no existe" if slot && !product_groups(product).include?(slot.downcase)
          { ingredient: ing, quantity: qty, size: size, slot: slot, position: i }
        end

        if problems.any?
          errors << "Recetario · #{label}: #{problems.uniq.to_sentence}. Se dejó la receta anterior."
          next
        end

        RecipeLine.transaction do
          product.recipe_lines.delete_all
          built.each { |attrs| product.recipe_lines.create!(attrs.except(:card)) }
        end
      end

      # Products whose card disappeared from the sheet lose their recipe
      # (only when the sheet clearly came through: at least 5 products read).
      stale = RecipeLine.where.not(product_id: touched)
      removed = stale.distinct.count(:product_id)
      if removed.positive? && touched.size >= 5
        stale.delete_all
        notes << "Se quitó la receta de #{removed} producto(s) que ya no están en Recetas POS."
      end
    end

    # ---------- Opciones ----------

    def sync_options
      rows = Array(@payload["opciones"]).map(&:to_h).reject { |r| r["grupo"].to_s.strip.blank? }
      slot_map  = {}   # option_choice_id => ingredient
      extra_map = Hash.new { |h, k| h[k] = {} } # option_choice_id => { ingredient => qty }
      specific  = {}   # option_choice_id => true once a product-specific rule applied

      # Rules for "todas" first, product-specific ones override.
      rows.sort_by { |r| TODAS.include?(r["producto"].to_s.strip.downcase) ? 0 : 1 }.each do |r|
        ing = find_ingredient(r["insumo"])
        unless ing
          errors << "Opciones: insumo \"#{r["insumo"]}\" no existe (#{r["grupo"]}: #{r["opcion"]})."
          next
        end
        qty = number(r["cantidad"])
        choices = matching_choices(r)
        if choices.empty?
          errors << "Opciones: no hay opción \"#{r["grupo"]}: #{r["opcion"]}\" en \"#{r["producto"]}\"."
          next
        end
        product_rule = !TODAS.include?(r["producto"].to_s.strip.downcase)
        choices.each do |choice|
          if product_rule && !specific[choice.id]
            slot_map.delete(choice.id)
            extra_map.delete(choice.id)
            specific[choice.id] = true
          end
          if qty&.positive?
            extra_map[choice.id][ing] = qty
          else
            slot_map[choice.id] = ing
          end
        end
      end
      return if errors.any? { |e| e.start_with?("Opciones") }

      OptionChoice.transaction do
        OptionChoice.where(active: true).find_each do |choice|
          choice.update_columns(ingredient_id: slot_map[choice.id]&.id)
          wanted = extra_map.fetch(choice.id, {})
          # Only rows pointing to current (Matriz) ingredients are managed here;
          # links to archived ingredients are left as they were.
          choice.option_choice_ingredients.includes(:ingredient).each do |oci|
            next if oci.ingredient.nil? || oci.ingredient.archived?
            oci.destroy unless wanted.key?(oci.ingredient)
          end
          wanted.each do |ing, qty|
            oci = choice.option_choice_ingredients.find_or_initialize_by(ingredient: ing)
            oci.update!(quantity_per_unit: qty)
          end
        end
      end
    end

    # ---------- helpers ----------

    def matching_choices(r)
      products = if TODAS.include?(r["producto"].to_s.strip.downcase)
                   Product.active.to_a
      else
                   [ find_product(r["producto"]) ].compact
      end
      group = r["grupo"].to_s.strip.downcase
      option = r["opcion"].to_s.strip.downcase
      products.flat_map do |p|
        p.option_groups.select { |g| g.name.to_s.strip.downcase == group }
         .flat_map { |g| g.option_choices.select { |c| c.name.to_s.strip.downcase == option } }
      end
    end

    def find_product(name)
      key = name.to_s.strip.downcase
      @products ||= {}
      @products[key] ||= Product.where("LOWER(TRIM(name)) = ?", key).order(active: :desc, id: :desc).first
    end

    def product_sizes(product)
      product.option_groups.select(&:size?).flat_map(&:option_choices).map { |c| c.name.to_s.strip.downcase }
    end

    def product_groups(product)
      product.option_groups.map { |g| g.name.to_s.strip.downcase }
    end

    def find_ingredient(value)
      key = value.to_s.strip
      return nil if key.blank?
      Ingredient.active.find_by(external_id: key) ||
        Ingredient.active.find_by("LOWER(TRIM(name)) = ?", key.downcase)
    end

    def unit_for(raw)
      UNIT_MAP[raw.to_s.strip.downcase] || "pza"
    end

    # "$1,599.00" -> 1599.0 ; "-" / "" -> nil
    def number(raw)
      return raw.to_d if raw.is_a?(Numeric)
      s = raw.to_s.strip.delete("$").delete(",").delete(" ")
      return nil if s.blank? || s == "-" || s == "—"
      BigDecimal(s)
    rescue ArgumentError
      nil
    end

    def pos_only_ingredients
      Ingredient.active.where("external_id LIKE 'POS-%'")
    end

    def serialize_new(i)
      {
        cod: i.external_id, articulo: i.name, marca: i.brand, cantidad: i.package_size&.to_f,
        unidad: i.package_unit.presence || i.unit, paquete: i.package_count&.to_f,
        precio: i.package_price&.to_f, precio_unitario: i.cost_per_unit.to_f,
        stock: i.stock.to_f, stock_unidad: i.unit, donde_comprar: i.supplier, seccion: i.section
      }
    end
  end
end
