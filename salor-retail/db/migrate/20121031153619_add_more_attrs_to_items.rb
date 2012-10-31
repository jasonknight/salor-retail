class AddMoreAttrsToItems < ActiveRecord::Migration
  def change
    add_column :items, :customs_code, :string
    add_column :items, :manufacturer_price, :float
    add_column :items, :origin_country, :string
  end
end
