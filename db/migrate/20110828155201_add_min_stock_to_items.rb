class AddMinStockToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :min_quantity, :float, :default => 0.0
  end

  def self.down
    remove_column :items, :min_quantity
  end
end
