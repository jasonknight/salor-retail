class AddRegisterIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :cash_register_id, :int
  end

  def self.down
    remove_column :orders, :cash_register_id
  end
end
