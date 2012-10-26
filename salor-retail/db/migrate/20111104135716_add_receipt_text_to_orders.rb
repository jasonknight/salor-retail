class AddReceiptTextToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :p_result, :string
    add_column :orders, :p_text, :string
  end

  def self.down
    remove_column :orders, :p_result
    remove_column :orders, :p_text
  end
end
