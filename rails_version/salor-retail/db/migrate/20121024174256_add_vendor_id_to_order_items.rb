class AddVendorIdToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :vendor_id, :integer
    vendor = Vendor.first
    OrderItem.connection.execute("update order_items set vendor_id = #{vendor.id}") if vendor
  end
end
