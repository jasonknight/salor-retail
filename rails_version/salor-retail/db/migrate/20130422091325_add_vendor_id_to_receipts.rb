class AddVendorIdToReceipts < ActiveRecord::Migration
  def change
    add_column :receipts, :vendor_id, :integer
    Receipt.connection.execute("update receipts as r set vendor_id = (select vendor_id from cash_registers where id = r.cash_register_id)")
  end
end
