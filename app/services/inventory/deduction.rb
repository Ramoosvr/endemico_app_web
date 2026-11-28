module Inventory
  # Works out which ingredients one order item consumes:
  # - the product's recipe lines for the chosen size, with "slot" lines
  #   (Leche, Sabor) taking the ingredient of the option the barista picked;
  # - option extras (shot, pump, flavor) through option_choice_ingredients;
  # - legacy product ingredients (removable / paid extras).
  # Archived ingredients (the old POS catalog) are ignored.
  class Deduction
    SIZE_GROUP = "tamaño".freeze

    Result = Struct.new(:amounts, :status, keyword_init: true)

    def self.for(item)
      new(item).call
    end

    def initialize(item)
      @item = item
    end

    def call
      qty = @item.quantity.to_i
      amounts = Hash.new { |h, k| h[k] = 0.to_d }
      return Result.new(amounts: {}, status: "ok") if qty <= 0

      product = @item.product
      chosen  = @item.chosen_options.to_a
      size    = chosen.find { |c| c.option_group_name.to_s.strip.downcase == SIZE_GROUP }&.choice_name
      has_recipe = product.recipe_lines.any?

      product.recipe_lines.each do |line|
        next unless line.applies_to_size?(size)
        ing = slot_ingredient(line, chosen) || line.ingredient
        next if ing.nil? || ing.archived?
        amounts[ing] += line.quantity.to_d * qty
      end

      chosen.each do |cop|
        choice = cop.option_choice
        next unless choice
        choice.option_choice_ingredients.each do |oci|
          ing = oci.ingredient
          next if ing.nil? || ing.archived? || oci.quantity_per_unit.to_d.zero?
          amounts[ing] += oci.quantity_per_unit.to_d * qty * [ cop.quantity.to_i, 1 ].max
        end
      end

      # Products with a recipe use only the recipe and option extras; the old
      # per-product ingredient list is kept for products without one.
      return Result.new(amounts: amounts.to_h, status: "ok") if has_recipe

      removed_ids = @item.removed_ingredients.map(&:ingredient_id).to_set
      extra_ids   = @item.extras.map(&:ingredient_id).to_set
      product.product_ingredients.each do |pi|
        ing = pi.ingredient
        next if ing.nil? || ing.archived? || pi.quantity_per_unit.to_d.zero?
        included = pi.default_included? ? !removed_ids.include?(pi.ingredient_id) : extra_ids.include?(pi.ingredient_id)
        amounts[ing] += pi.quantity_per_unit.to_d * qty if included
      end

      Result.new(amounts: amounts.to_h, status: "sin_receta")
    end

    private

    def slot_ingredient(line, chosen)
      return nil if line.slot.blank?
      cop = chosen.find { |c| c.option_group_name.to_s.strip.casecmp?(line.slot.to_s.strip) }
      cop&.option_choice&.ingredient
    end
  end
end
