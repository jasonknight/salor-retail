APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require APP_PATH
require File.expand_path('../../config/environment',  __FILE__)

Item.select('id,sku,quantity_sold').where("quantity_sold < 0").find_each(:batch_size => 200) do |item|
  count = 0
  item.order_items.each do |oi|
    count += 1 if oi.order.paid == 1
  end
  puts "New quantity_sold for #{item.sku} #{count}"
  item.update_attribute :quantity_sold, count
end