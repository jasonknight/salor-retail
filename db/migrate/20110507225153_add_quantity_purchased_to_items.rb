class AddQuantityPurchasedToItems < ActiveRecord::Migration
  def self.up
    #add_column :items, :quantity_purchased, :int
  end

  def self.down
    #remove_column :items, :quantity_purchased
  end
end
