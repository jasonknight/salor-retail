class AddCountryToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :country, :string, :default => 'cc'
  end
end
