class AddPaidToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :paid, :integer
  end

  def self.down
    remove_column :orders, :paid
  end
end
