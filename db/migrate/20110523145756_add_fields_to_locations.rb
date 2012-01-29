class AddFieldsToLocations < ActiveRecord::Migration
  def self.up
    add_column :locations, :quantity_sold, :float, :default => 0
    add_column :locations, :cash_made, :float, :default => 0
  end

  def self.down
    remove_column :locations, :cash_made
    remove_column :locations, :quantity_sold
  end
end
