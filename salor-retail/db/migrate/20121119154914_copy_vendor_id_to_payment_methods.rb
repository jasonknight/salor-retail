class CopyVendorIdToPaymentMethods < ActiveRecord::Migration
  def up
    PaymentMethod.update_all :vendor_id => Vendor.first.id
  end

  def down
  end
end
