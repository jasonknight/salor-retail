class AddPriceByToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :price_by_qty, :boolean
  end

  def self.down
    remove_column :items, :price_by_qty
  end
end
