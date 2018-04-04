class TransformPaymentMethods3 < ActiveRecord::Migration
  def up
    
    
    
    # assign user_id to all pmitems according to the belonging order
    Vendor.connection.execute("UPDATE payment_method_items,orders SET payment_method_items.user_id = orders.user_id WHERE orders.id = payment_method_items.order_id")
    
    # assign drawer_id to all pmitems according to the belonging user
    Vendor.connection.execute("UPDATE payment_method_items,users SET payment_method_items.drawer_id = users.drawer_id WHERE users.id = payment_method_items.user_id")
    
    # assign drawer_id to all pmitems according to the belonging user, but ONLY uses_dawer_id, selectively overwriting the last sql statement
    Vendor.connection.execute("UPDATE payment_method_items,users SET payment_method_items.drawer_id = users.uses_drawer_id WHERE users.id = payment_method_items.user_id AND users.uses_drawer_id IS NOT NULL")
  end

  def down
  end
end
