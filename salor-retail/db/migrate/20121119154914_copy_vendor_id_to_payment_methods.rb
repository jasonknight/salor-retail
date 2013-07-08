class CopyVendorIdToPaymentMethods < ActiveRecord::Migration
  def up
    vendor = Vendor.first
    PaymentMethod.update_all :vendor_id => vendor.id if vendor
  end

  def down
  end
end
