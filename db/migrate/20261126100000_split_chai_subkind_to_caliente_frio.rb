class SplitChaiSubkindToCalienteFrio < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE products SET subkind = 'chai_caliente' WHERE subkind = 'chai'"
  end

  def down
    execute "UPDATE products SET subkind = 'chai' WHERE subkind IN ('chai_caliente', 'chai_frio')"
  end
end
