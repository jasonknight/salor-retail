class RemoveCashRegisterFromDrawerTransactions < ActiveRecord::Migration
  def up
    remove_column :drawer_transactions, :cash_register_id
  end

  def down
  end
end
