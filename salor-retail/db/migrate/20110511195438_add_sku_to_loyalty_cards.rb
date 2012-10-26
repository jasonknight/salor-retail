class AddSkuToLoyaltyCards < ActiveRecord::Migration
  def self.up
    add_column :loyalty_cards, :sku, :string
  end

  def self.down
    remove_column :loyalty_cards, :sku
  end
end
