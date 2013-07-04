class TransformPaymentMethods < ActiveRecord::Migration
  def up
    
    v = Order.last.vendor
    v ||= Vendor.visible.first
    
    PaymentMethod.reset_column_information
    
    # cash
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.cash = true
    pm.name = "InCash"
    pm.save
    
    # change
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.change = true
    pm.name = "Change"
    pm.save
    
    # OtherCredit
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.name = "OtherCredit"
    pm.save
    
    # ByGiftCard
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.name = "ByGiftCard"
    pm.save
    
    # Unpaid
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.name = "Unpaid"
    pm.save
    
    # Quote
    pm = PaymentMethod.new
    pm.vendor = v
    pm.company = v.company
    pm.name = "Quote"
    pm.save
  end

  def down
  end
end
