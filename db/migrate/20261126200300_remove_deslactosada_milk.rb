class RemoveDeslactosadaMilk < ActiveRecord::Migration[8.1]
  # Choices that are no longer offered are hidden (past sales point to them)
  # or deleted when nothing references them.
  def up
    add_column :option_choices, :active, :boolean, default: true, null: false

    ids = select_values(<<~SQL)
      SELECT option_choices.id FROM option_choices
      JOIN option_groups ON option_groups.id = option_choices.option_group_id
      WHERE option_groups.name = 'Leche' AND option_choices.name = 'Deslactosada'
    SQL
    return if ids.empty?

    used = select_values("SELECT DISTINCT option_choice_id FROM order_item_option_choices WHERE option_choice_id IN (#{ids.join(',')})")
    unused = ids.map(&:to_i) - used.map(&:to_i)

    execute "UPDATE option_choices SET active = 0, default_selected = 0 WHERE id IN (#{used.join(',')})" if used.any?
    if unused.any?
      execute "DELETE FROM option_choice_ingredients WHERE option_choice_id IN (#{unused.join(',')})"
      execute "DELETE FROM option_choices WHERE id IN (#{unused.join(',')})"
    end
  end

  def down
    remove_column :option_choices, :active
  end
end
