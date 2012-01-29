class AddIsBuybackToItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :is_buyback, :boolean, :default => false
  end

  def self.down
    remove_column :order_items, :is_buyback
  end
end
