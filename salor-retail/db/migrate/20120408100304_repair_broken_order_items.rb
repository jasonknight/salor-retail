class RepairBrokenOrderItems < ActiveRecord::Migration
  def up
#     msg = "See migration RepairBrokenOrderItems: Retroactively fixing nulled price field on older gift card OrderItems to eradicate calculation errors in reports."
#     h = History.new(:owner_type => "System",:owner_id => '1', :sensitivity => 1,:changes_made => {:msg => ['',msg]}.to_json)
#     h.save
#     OrderItem.where("(activated IS FALSE or activated != 1) and price = 0.0").each do |oi|
#       if oi.order and oi.order.paid == 1 then
#         p = oi.item.base_price
#         bp = (p *(100 / (100 + (100 * (oi.tax_profile_amount/100))))).round(2);
#         t = (p - bp).round(2)
#         OrderItem.connection.execute("update order_items set tax = #{t},price = '#{oi.item.base_price}', total = '#{oi.item.base_price * oi.quantity}' where id = #{oi.id}")
#       end
#     end
  end

  def down
  end
end
