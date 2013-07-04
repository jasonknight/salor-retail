class TransformPaymentMethods2 < ActiveRecord::Migration
  def up
    v = Order.last.vendor
    v ||= Vendor.visible.first
    
    # add missing ByCard pm
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.name = "ByCard"
    pm.save  
  end

  def down
  end
end
