class CopyDrawerIdFromDrawerTransactions < ActiveRecord::Migration
  def up
    # the authority on the drawer_id for Order, OrderItem, PaymentMethodItem  is DrawerTransaction
    Vendor.connection.execute("UPDATE orders, drawer_transactions SET orders.drawer_id=drawer_transactions.drawer_id WHERE drawer_transactions.order_id = orders.id")
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.drawer_id=orders.drawer_id WHERE order_items.order_id = orders.id")
    Vendor.connection.execute("UPDATE payment_method_items,orders SET payment_method_items.drawer_id=orders.drawer_id WHERE payment_method_items.order_id = orders.id")
  end

  def down
  end
end
