class InvertOiPmiRelationship < ActiveRecord::Migration
  def up
    Vendor.connection.execute("UPDATE payment_method_items,order_items SET payment_method_items.order_item_id = order_items.id WHERE order_items.refund_payment_method_item_id = payment_method_items.id")
    remove_column :order_items, :refund_payment_method_item_id
  end

  def down
  end
end
