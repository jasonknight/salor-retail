class FixVendorIdsOnReceipts < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    Receipt.connection.execute("update receipts set vendor_id = #{vendor.id}") if vendor
  end

  def down
  end
end
