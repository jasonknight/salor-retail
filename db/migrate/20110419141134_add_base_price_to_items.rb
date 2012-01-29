class AddBasePriceToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :base_price, :float, :default => 0
  end

  def self.down
    remove_column :items, :base_price
  end
end
