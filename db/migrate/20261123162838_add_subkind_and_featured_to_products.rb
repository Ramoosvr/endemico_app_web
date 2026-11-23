class AddSubkindAndFeaturedToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :subkind,  :string
    add_column :products, :featured, :boolean, default: false, null: false
    add_index  :products, [:kind, :subkind]
    add_index  :products, :featured
  end
end
