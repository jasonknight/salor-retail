class AddBkasseFieldsToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :bk_msgs_received, :text
  end

  def self.down
    remove_column :orders, :bk_msgs_received
  end
end
