class AddDrawerAmountToDrawerTransactions < ActiveRecord::Migration
  def self.up
    add_column :drawer_transactions, :drawer_amount, :float, :default => 0.0
  end

  def self.down
    remove_column :drawer_transactions, :drawer_amount
  end
end
