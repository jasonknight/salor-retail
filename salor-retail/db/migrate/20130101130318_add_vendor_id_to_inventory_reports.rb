class AddVendorIdToInventoryReports < ActiveRecord::Migration
  def change
    add_column :inventory_reports, :vendor_id, :integer
    add_column :inventory_report_items, :vendor_id, :integer
    add_index :inventory_report_items, :vendor_id
    add_index :inventory_reports, :vendor_id
  end
end
