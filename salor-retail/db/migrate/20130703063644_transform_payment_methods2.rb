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
    
    # set belongs_to relationship between all pmitems and pms
    Vendor.connection.execute("UPDATE payment_method_items,payment_methods SET payment_method_items.payment_method_id = payment_methods.id WHERE payment_methods.name = payment_method_items.internal_type")
    
    # set boolean flags according to internal_type
    Vendor.connection.execute('UPDATE payment_method_items SET `change` = TRUE WHERE internal_type = "Change"')
    Vendor.connection.execute('UPDATE payment_method_items SET `cash` = TRUE WHERE internal_type = "InCash"')
    
    # get rid of internal_type
    remove_colum :payment_method_items, :internal_type
    remove_colum :payment_methods, :internal_type    
  end

  def down
  end
end
