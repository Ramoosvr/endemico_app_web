class AddAvailableToOptionChoices < ActiveRecord::Migration[8.1]
  # An option that runs out (e.g. chai "Especias") stays visible in the
  # order pop-up but can't be picked until it is marked available again.
  def up
    add_column :option_choices, :available, :boolean, default: true, null: false

    # Only vanilla chai is being sold for now.
    execute <<~SQL
      UPDATE option_choices SET available = 0
      WHERE name = 'Especias'
        AND option_group_id IN (SELECT id FROM option_groups WHERE name = 'Sabor')
    SQL
  end

  def down
    remove_column :option_choices, :available
  end
end
