class AddVendorIdToDrawerTransactions < ActiveRecord::Migration
  def change
    add_column :drawer_transactions, :vendor_id, :integer
  end
end
