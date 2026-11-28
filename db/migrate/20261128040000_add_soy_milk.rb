class AddSoyMilk < ActiveRecord::Migration[8.1]
  # Soy milk joins the plant milks: offered in every "Leche" group, $10 extra.
  def up
    execute <<~SQL
      INSERT INTO option_choices (option_group_id, name, extra_price, default_selected, position, available, active, created_at, updated_at)
      SELECT option_groups.id, 'Soya', 10, 0,
             COALESCE((SELECT MAX(position) + 1 FROM option_choices oc WHERE oc.option_group_id = option_groups.id), 0),
             1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM option_groups
      WHERE option_groups.name = 'Leche'
        AND NOT EXISTS (
          SELECT 1 FROM option_choices oc
          WHERE oc.option_group_id = option_groups.id AND oc.name = 'Soya'
        )
    SQL
  end

  def down
    ids = select_values(<<~SQL)
      SELECT option_choices.id FROM option_choices
      JOIN option_groups ON option_groups.id = option_choices.option_group_id
      WHERE option_groups.name = 'Leche' AND option_choices.name = 'Soya'
    SQL
    return if ids.empty?

    used = select_values("SELECT DISTINCT option_choice_id FROM order_item_option_choices WHERE option_choice_id IN (#{ids.join(',')})").map(&:to_i)
    unused = ids.map(&:to_i) - used
    execute "UPDATE option_choices SET active = 0 WHERE id IN (#{used.join(',')})" if used.any?
    if unused.any?
      execute "DELETE FROM option_choice_ingredients WHERE option_choice_id IN (#{unused.join(',')})"
      execute "DELETE FROM option_choices WHERE id IN (#{unused.join(',')})"
    end
  end
end
