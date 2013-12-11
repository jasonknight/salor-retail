class CopyIsProformaToOrderItems < ActiveRecord::Migration
  def up
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.is_proforma = orders.is_proforma WHERE order_items.order_id = orders.id")
  end

  def down
  end
end
