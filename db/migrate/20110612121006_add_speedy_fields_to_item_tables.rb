class AddSpeedyFieldsToItemTables < ActiveRecord::Migration
  def self.up
    add_column :order_items, :behavior,           :string
    add_column :order_items, :tax_profile_amount, :float, :default => 0
    add_column :order_items, :category_id,        :integer
    add_column :order_items, :location_id,        :integer
    add_column :order_items, :amount_remaining,   :float, :default => 0
    add_column :items, :behavior,           :string
    add_column :items, :tax_profile_amount, :float, :default => 0
  end

  def self.down
    remove_column :order_items, :behavior         
    remove_column :order_items, :tax_profile_amount
    remove_column :order_items, :category_id      
    remove_column :order_items, :location_id 
    remove_column :order_items, :amount_remaining
    remove_column :items, :behavior         
    remove_column :items, :tax_profile_amount
  end
end
