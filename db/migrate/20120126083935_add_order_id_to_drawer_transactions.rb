class AddOrderIdToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :order_id, :integer
  end

  def self.down
    remove_column :drawer_transactions, :order_id
  end
end
