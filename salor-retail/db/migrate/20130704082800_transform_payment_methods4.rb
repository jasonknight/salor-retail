class TransformPaymentMethods4 < ActiveRecord::Migration
  def up
    
    Vendor.connection.execute('UPDATE payment_method_items SET internal_type = "Paybox" WHERE internal_type = "Handy verkauf" OR internal_type = "HandyVerkauf"')
    
    
    puts "set boolean flags of PaymentMethodItem according to internal_type"
    Vendor.connection.execute('UPDATE payment_method_items SET `change` = TRUE WHERE internal_type = "Change"')
    Vendor.connection.execute('UPDATE payment_method_items SET `cash` = TRUE WHERE internal_type LIKE "InCas%"')
    Vendor.connection.execute('UPDATE payment_method_items SET `refund` = TRUE WHERE internal_type LIKE "%efund"')
        
    puts "make relationship between all pmitems and pms"
    Vendor.connection.execute("UPDATE payment_method_items,payment_methods SET payment_method_items.payment_method_id = payment_methods.id WHERE payment_methods.name LIKE CONCAT( SUBSTRING(payment_method_items.internal_type, 1, 4), '%')")
    
    puts "setting refund flag to nil where false in DrawerTransaction"
    Vendor.connection.execute("UPDATE drawer_transactions SET refund = NULL WHERE refund = FALSE")    

    
    # get rid of internal_type
    # remove_column :payment_method_items, :internal_type
    # remove_column :payment_methods, :internal_type  
  end

  def down
  end
end
