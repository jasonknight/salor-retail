class AlterItemSkuOnDiscounts < ActiveRecord::Migration
  def self.up
    change_column(:discounts, :item_sku, :string)
  end

  def self.down
  end
end
