class AddCalculateTaxToVendors < ActiveRecord::Migration
  def self.up
    add_column :vendors, :calculate_tax, :boolean
  end

  def self.down
    remove_column :vendors, :calculate_tax
  end
end
