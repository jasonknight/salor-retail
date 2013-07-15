class CopyAndFixTimestamps < ActiveRecord::Migration
  def up
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.completed_at = orders.created_at WHERE order_items.order_id = orders.id")
    Vendor.connection.execute("UPDATE orders SET completed_at = created_at")
  end

  def down
  end
end
