class AddPurchasePriceToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :purchase_price, :float
  end

  def self.down
    remove_column :items, :purchase_price
  end
end
