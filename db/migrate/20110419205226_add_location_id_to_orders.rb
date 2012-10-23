class AddLocationIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :location_id, :integer
  end

  def self.down
    remove_column :orders, :location_id
  end
end
