class TransformCalcFields < ActiveRecord::Migration
  def up    
    puts "set OrderItem rebate_amount to NULL when zero"
    Vendor.connection.execute("UPDATE order_items SET rebate_amount = NULL WHERE rebate_amount = 0")
    
    puts "copy OrderItem total to OrderItem subtotal for normal items since subtotal is a new field"
    Vendor.connection.execute("UPDATE order_items SET subtotal = total")

    puts "invert OrderItem subtotal for activated gift cards"
    Vendor.connection.execute("UPDATE order_items SET subtotal = subtotal * -1, total = total * -1, price = price * -1 WHERE behavior = 'gift_card' AND activated = TRUE")
    
    puts "set OrderItem subtotal to zero for refunded"
    Vendor.connection.execute("UPDATE order_items SET subtotal = 0 WHERE refunded = TRUE")
    
    puts "assign OrderItem to Drawer according to Order"
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.drawer_id = orders.drawer_id WHERE orders.id = order_items.order_id")
  end

  def down
  end
end
