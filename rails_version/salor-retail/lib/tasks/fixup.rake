namespace :salor do
  task :fix_weird_skus => [:environment] do
    Vendor.all.each do |vendor|
      vendor.items.each do |item|
        item.sku = item.sku.gsub(/[^0-9a-zA-B]/,'')
        if not item.save then
          item.sku = "CHECKME" + item.sku
          item.save
        end
      end
    end
  end
end