class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "barista", null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE users SET role = 'admin'"
      end
    end
  end
end
