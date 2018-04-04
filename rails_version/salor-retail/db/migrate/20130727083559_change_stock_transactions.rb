class ChangeStockTransactions < ActiveRecord::Migration
  def up
    change_column :stock_transactions, :from_type, :string
    change_column :stock_transactions, :to_type, :string
  end

  def down
  end
end
