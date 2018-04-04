class AddJindToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :j_ind, :string
  end

  def self.down
    remove_column :orders, :j_ind
  end
end
