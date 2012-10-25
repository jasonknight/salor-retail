class AddVendorIdToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :vendor_id, :integer
    vendor = Vendor.first
    OrderItem.all.each do |oi|
      oi.vendor_id = vendor.id
      oi.save
    end
  end
end
