class AddLastOrderIdToMeta < ActiveRecord::Migration
  def self.up
    add_column :meta, :last_order_id, :integer
  end

  def self.down
    remove_column :meta, :last_order_id
  end
end
