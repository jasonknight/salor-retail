APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require APP_PATH
require File.expand_path('../../config/environment',  __FILE__)

Item.where(:packaging_unit => 200).each do |item|
  child = item.child
  if child and child.quantity > 0 then
    puts "Need to fix: #{child.quantity} for #{child.sku}"
    diff = (200 - child.quantity) / 10
    new_qty = diff.to_s.split('.').last
    sub_from_parent = diff.to_s.split('.').first.to_i
    puts "diff is: #{diff} parent.qty #{item.quantity} parent.new_qty #{item.quantity - sub_from_parent if item.quantity > sub_from_parent} child.new_qty #{new_qty}\n"
    if item.quantity > sub_from_parent then
      item.update_attribute :quantity, item.quantity - sub_from_parent
    end
    item.update_attribute :packaging_unit, 20
    child.update_attribute :quantity, new_qty
  end
end