class AddCountriesAndSaleTypeToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :origin_country_id, :integer
    add_column :orders, :destination_country_id, :integer
    add_column :orders, :sale_type_id, :integer
  end
end
