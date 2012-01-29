class AddTagToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :tag, :string
  end

  def self.down
    remove_column :orders, :tag
  end
end
