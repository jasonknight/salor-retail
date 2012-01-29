class AddQuantityBuybackToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :quantity_buyback, :integer, :default => 0
  end

  def self.down
    remove_column :items, :quantity_buyback
  end
end
