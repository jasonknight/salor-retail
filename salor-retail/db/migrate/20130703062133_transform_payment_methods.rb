class TransformPaymentMethods < ActiveRecord::Migration
  def up
    
    v = Order.last.vendor if Order.last
    v ||= Vendor.visible.first
    
    PaymentMethod.reset_column_information
    
    if v
    
      # cash
      pm = PaymentMethod.new
      pm.vendor = v
      pm.company = v.company
      pm.cash = true
      pm.name = "InCash"
      pm.save( :validate => false )
      
      # change
      pm = PaymentMethod.new
      pm.vendor = v
      pm.company = v.company
      pm.change = true
      pm.name = "Change"
      pm.save( :validate => false )
      
      # OtherCredit
      pm = PaymentMethod.new
      pm.vendor = v
      pm.company = v.company
      pm.name = "OtherCredit"
      pm.save( :validate => false )
      
      # ByGiftCard
      pm = PaymentMethod.new
      pm.vendor = v
      pm.company = v.company
      pm.name = "ByGiftCard"
      pm.save( :validate => false )
      
      # Unpaid
      pm = PaymentMethod.new
      pm.vendor = v
      pm.company = v.company
      pm.name = "Unpaid"
      pm.save( :validate => false )
      
      # Quote
      pm = PaymentMethod.new
      pm.vendor = v
      pm.company = v.company
      pm.name = "Quote"
      pm.save( :validate => false )
    end
  end

  def down
  end
end
