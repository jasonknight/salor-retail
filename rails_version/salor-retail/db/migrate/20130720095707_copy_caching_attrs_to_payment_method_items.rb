class CopyCachingAttrsToPaymentMethodItems < ActiveRecord::Migration
  def up   
    # those attrs actually are a logical property of Order, but since we need to run exensive statistics and report generation, we need to copy all those to the PaymentMethodItem model. selecting by an array of order_ids has been tried and is extremely slow. so that is the solution.
    Vendor.connection.execute("UPDATE payment_method_items,orders SET payment_method_items.is_quote = orders.is_quote, payment_method_items.is_unpaid = orders.is_unpaid, payment_method_items.paid = orders.paid, payment_method_items.paid_at = orders.paid_at, payment_method_items.created_at=orders.created_at, payment_method_items.completed_at=orders.completed_at WHERE payment_method_items.order_id = orders.id")
  end

  def down
  end
end
