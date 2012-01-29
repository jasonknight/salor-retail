class AddIsRefundToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :is_refund, :boolean, :default => false
  end

  def self.down
    remove_column :drawer_transactions, :is_refund
  end
end
