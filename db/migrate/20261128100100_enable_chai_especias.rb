# Chai de especias is back in stock: make the "Especias" flavor selectable again.
class EnableChaiEspecias < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE option_choices SET available = 1
      WHERE name = 'Especias'
        AND option_group_id IN (SELECT id FROM option_groups WHERE name = 'Sabor')
    SQL
  end

  def down
    execute <<~SQL
      UPDATE option_choices SET available = 0
      WHERE name = 'Especias'
        AND option_group_id IN (SELECT id FROM option_groups WHERE name = 'Sabor')
    SQL
  end
end
