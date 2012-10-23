class AddHiddenFields < ActiveRecord::Migration
  def self.up
    add_column :tax_profiles, :hidden, :integer, :default => 0
    add_column :vendors, :hidden, :integer, :default => 0
    add_column :shippers, :hidden, :integer, :default => 0
    add_column :shipments, :hidden, :integer, :default => 0
    add_column :employees, :hidden, :integer, :default => 0
  end

  def self.down
    remove_column :tax_profiles, :hidden
    remove_column :vendors, :hidden 
    remove_column :shippers, :hidden
    remove_column :shipments, :hidden
    remove_column :employees, :hidden
  end                                    
end
