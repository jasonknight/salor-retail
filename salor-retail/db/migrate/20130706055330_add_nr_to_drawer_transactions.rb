class AddNrToDrawerTransactions < ActiveRecord::Migration
  def change
    add_column :drawer_transactions, :nr, :integer
    add_column :vendors, :largest_drawer_transaction_number, :integer
    
    Vendor.reset_column_information
    
    Vendor.connection.execute("UPDATE drawer_transactions SET nr=id")
    Vendor.update_all :largest_drawer_transaction_number => DrawerTransaction.last.id
  end
end
