class TransformDrawerTransactions < ActiveRecord::Migration
  def up
    Vendor.connection.execute("UPDATE drawer_transactions SET amount = amount * -1 WHERE payout=1;")
    remove_column :drawer_transactions, :drop
    remove_column :drawer_transactions, :payout
  end

  def down
  end
end
