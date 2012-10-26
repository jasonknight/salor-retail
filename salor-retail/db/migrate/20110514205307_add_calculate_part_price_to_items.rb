class AddCalculatePartPriceToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :calculate_part_price, :boolean, :default => false
  end

  def self.down
    remove_column :items, :calculate_part_price
  end
end
