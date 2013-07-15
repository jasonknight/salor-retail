class ChangesForReports < ActiveRecord::Migration
  def up
    add_column :order_items, :drawer_id, :integer
    add_column :payment_methods, :drawer_id, :integer
    add_column :payment_methods, :payment_method_id, :integer
    remove_column :payment_methods, :name
    add_column :receipts, :drawer_id, :integer
    drop_table :vendor_printers
    rename_table :payment_methods, :payment_method_items
    rename_table :tender_methods, :payment_methods
  end

  def down
  end
end
