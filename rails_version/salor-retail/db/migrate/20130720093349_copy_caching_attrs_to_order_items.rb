class CopyCachingAttrsToOrderItems < ActiveRecord::Migration
  def up
    # we have to fix a previous migration. Orders with paid=nil cannot be completed or paid
    Vendor.connection.execute("UPDATE orders SET completed_at=NULL, paid_at=NULL WHERE paid IS NULL")
    
    # those attrs actually are a logical property of Order, but since we need to run exensive statistics and report generation, we need to copy all those to the OrderItem model. selecting by an array of order_ids has been tried and is extremely slow. so that is the solution.
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.is_quote = orders.is_quote, order_items.is_unpaid = orders.is_unpaid, order_items.paid = orders.paid, order_items.paid_at = orders.paid_at, order_items.created_at=orders.created_at, order_items.completed_at=orders.completed_at WHERE order_items.order_id = orders.id")
  
    
  end

  def down
  end
end
