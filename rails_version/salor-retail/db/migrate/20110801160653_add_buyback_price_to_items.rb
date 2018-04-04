class AddBuybackPriceToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :buyback_price, :float, :default => 0.0
  end

  def self.down
    remove_column :items, :buyback_price
  end
end
