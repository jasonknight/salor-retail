class AddMustChangePriceToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :must_change_price, :boolean, :default => false
  end

  def self.down
    remove_column :items, :must_change_price
  end
end
