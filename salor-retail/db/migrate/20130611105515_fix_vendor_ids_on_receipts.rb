class FixVendorIdsOnReceipts < ActiveRecord::Migration
  def up
    vid = Vendor.first.id
    Receipt.connection.execute("update receipts set vendor_id = #{vid}")
  end

  def down
  end
end
