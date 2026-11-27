class PlantMilkSurcharge < ActiveRecord::Migration[8.1]
  # Oat, almond and coconut milk cost $10 more in every drink.
  MILKS = %w[Avena Almendra Coco].freeze

  def up
    execute <<~SQL
      UPDATE option_choices SET extra_price = 10
      WHERE name IN (#{MILKS.map { |m| quote(m) }.join(', ')})
        AND option_group_id IN (SELECT id FROM option_groups WHERE name = 'Leche')
    SQL
  end

  def down
    execute <<~SQL
      UPDATE option_choices SET extra_price = 0
      WHERE name IN (#{MILKS.map { |m| quote(m) }.join(', ')})
        AND option_group_id IN (SELECT id FROM option_groups WHERE name = 'Leche')
    SQL
  end
end
