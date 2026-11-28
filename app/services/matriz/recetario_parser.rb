module Matriz
  # Reads the "Recetario" tab of Matriz exactly as Diego writes it (cost cards
  # side by side) and turns it into recipe rows for the POS, using the
  # "Equivalencias POS" tab to translate names.
  #
  # A card looks like:
  #   Nombre | Latte 12oz
  #   ...
  #   No. Porciones | 1
  #   ...
  #   Pasos | Ingredientes | Cantidad | Unidad | ...
  #         | Cafe en grano | 20 | gr
  #         | Leche         | 210 | ml
  #   ...   (until "Costo Insumos")
  #
  # Equivalencias rows (header row is skipped):
  #   TIPO | NOMBRE | EN EL POS | TAMAÑO | SE ELIGE EN | CANTIDAD | SOLO EN PRODUCTO
  #   bebida | Latte 12oz | Latte | 12 oz
  #   insumo | Leche | Leche entera | | Leche
  #   insumo | Cuchara | NO DESCONTAR
  #   opcion | Leche: Avena | Leche de avena
  #   producto | Coca | Coca | | | 1            (products without a card)
  #   opcion | Shot extra de espresso: Shot extra de espresso | Café en grano | | | 20
  class RecetarioParser
    SKIP = [ "no descontar", "no se descuenta", "-" ].freeze
    MAX_INGREDIENT_ROWS = 25

    Card = Struct.new(:name, :portions, :ingredients, keyword_init: true)

    attr_reader :errors, :notes, :recipes, :options

    def initialize(grid, equivalencias)
      @grid = Array(grid).map { |row| Array(row).map { |v| v.to_s.strip } }
      @eq = Array(equivalencias).map { |row| Array(row).map { |v| v.to_s.strip } }
      @errors = []
      @notes = []
      @recipes = []
      @options = []
    end

    def call
      load_equivalencias
      cards.each { |card| add_card(card) }
      self
    end

    def cards
      @cards ||= begin
        found = []
        @grid.each_with_index do |row, r|
          row.each_with_index do |cell, c|
            next unless cell.casecmp?("Nombre") && row[c + 1].present?
            found << read_card(r, c)
          end
        end
        found.compact
      end
    end

    private

    def read_card(r, c)
      name = @grid[r][c + 1]
      portions = 1.to_d
      header = nil
      (r + 1..[ r + 15, @grid.size - 1 ].min).each do |i|
        label = @grid[i][c].to_s
        portions = number(@grid[i][c + 1]) || portions if label.casecmp?("No. Porciones")
        if @grid[i][c + 1].to_s.casecmp?("Ingredientes")
          header = i
          break
        end
      end
      return nil unless header

      ingredients = []
      (header + 1..[ header + MAX_INGREDIENT_ROWS, @grid.size - 1 ].min).each do |i|
        row = @grid[i]
        break if row[c + 4].to_s.casecmp?("Costo Insumos")
        ing = row[c + 1].to_s
        next if ing.blank?
        ingredients << { name: ing, quantity: row[c + 2], unit: row[c + 3] }
      end
      portions = 1.to_d unless portions&.positive?
      Card.new(name: name, portions: portions, ingredients: ingredients)
    end

    def load_equivalencias
      @drinks = {}
      @insumos = {}
      @eq.drop(1).each do |row|
        tipo, nombre, pos, tamano, elige, cantidad, producto = row
        next if nombre.blank?
        case tipo.to_s.downcase
        when "bebida"
          (@drinks[nombre.downcase] ||= []) << { producto: pos, tamano: tamano.presence }
        when "insumo"
          @insumos[nombre.downcase] = { insumo: pos, elegido_en: elige.presence }
        when "producto"
          # Product without a card (bottles, desserts): one ingredient, fixed quantity.
          @recipes << { "producto" => nombre, "tamano" => tamano.presence, "insumo" => pos,
                        "cantidad" => cantidad, "elegido_en" => nil, "tarjeta" => nombre }
        when "opcion", "opción"
          grupo, opcion = nombre.split(":", 2).map { |s| s.to_s.strip }
          opcion = grupo if opcion.blank?
          @options << { "producto" => producto.presence || "todas", "grupo" => grupo, "opcion" => opcion,
                        "insumo" => pos, "cantidad" => cantidad.presence }
        end
      end
    end

    def add_card(card)
      targets = @drinks[card.name.downcase] || [ { producto: card.name, tamano: nil } ]
      card.ingredients.each do |ing|
        map = @insumos[ing[:name].downcase] || { insumo: ing[:name], elegido_en: nil }
        next if SKIP.include?(map[:insumo].to_s.downcase)
        qty = number(ing[:quantity])
        if qty.nil?
          errors << "Recetario · #{card.name}: la cantidad de \"#{ing[:name]}\" (\"#{ing[:quantity]}\") no es un número."
          next
        end
        # Batch cards (Cold Brew: 11 portions) divide what goes into the batch;
        # cups, lids and other pieces are per drink already.
        piece = ing[:unit].to_s.strip.downcase.in?(%w[pza pieza piezas])
        per_drink = piece ? qty : (qty / card.portions).round(3)
        targets.each do |t|
          next if t[:producto].to_s.downcase.in?(SKIP)
          @recipes << { "producto" => t[:producto], "tamano" => t[:tamano], "insumo" => map[:insumo],
                        "cantidad" => per_drink, "elegido_en" => map[:elegido_en], "tarjeta" => card.name }
        end
      end
    end

    def number(raw)
      s = raw.to_s.strip.delete("$").delete(",")
      return nil if s.blank? || s == "-"
      BigDecimal(s)
    rescue ArgumentError
      nil
    end
  end
end
