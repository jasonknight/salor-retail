class AddQuantitySoldToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :quantity_sold, :float, :default => 0
  end

  def self.down
    remove_column :categories, :quantity_sold
  end
end
