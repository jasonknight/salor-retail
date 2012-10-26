class AddMoreIndexes < ActiveRecord::Migration
  def self.up
    add_index :tax_profiles, :hidden
    add_index :meta, :ownable_type
    add_index :order_items, :is_buyback
  end

  def self.down
    remove_index :tax_profiles, :hidden
    remove_index :meta, :ownable_type
    remove_index :order_items, :is_buyback 
  end
end
