class AddAcontoItemType < ActiveRecord::Migration
  def up
    Vendor.all.each do |v|
      it = ItemType.new
      it.vendor = v
      it.company = v.company
      it.behavior = 'aconto'
      it.name = 'a conto'
      it.save
      Vendor.connection.execute("UPDATE items SET item_type_id=#{ it.id } WHERE sku = 'DMYACONTO' AND vendor_id=#{ v.id }")
      Vendor.connection.execute("UPDATE order_items SET item_type_id=#{ it.id } WHERE sku = 'DMYACONTO' AND vendor_id=#{ v.id }")
    end
  end

  def down
  end
end
