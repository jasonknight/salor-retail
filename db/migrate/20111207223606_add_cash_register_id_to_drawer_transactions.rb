class AddCashRegisterIdToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :cash_register_id, :integer
  end

  def self.down
    remove_column :drawer_transactions, :cash_register_id
  end
end
