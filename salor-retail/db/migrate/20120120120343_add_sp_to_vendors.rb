class AddSpToVendors < ActiveRecord::Migration
  def self.up
    add_column :configurations, :salor_printer, :boolean, :default => false
  end

  def self.down
    remove_column :configurations, :salor_printer
  end
end
