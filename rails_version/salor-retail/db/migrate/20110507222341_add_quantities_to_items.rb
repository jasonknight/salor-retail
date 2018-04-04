class AddQuantitiesToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :quantity, :float, :default => 0
    add_column :items, :quantity_sold, :float, :default => 0
  end

  def self.down
    remove_column :items, :quantity_sold
    remove_column :items, :quantity
  end
end
