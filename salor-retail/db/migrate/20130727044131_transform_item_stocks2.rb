class TransformItemStocks2 < ActiveRecord::Migration
  def up
    
    # Existing ItemStocks will be transformed into ItemStock of location_type Location.
    Vendor.connection.execute("UPDATE item_stocks SET quantity = location_quantity, location_type = 'Location' ")
    
    # next, separate out stock_locations, those are polymorphic now
    if ItemStock.respond_to? :visible then
      ItemStock.visible.where('stock_location_id IS NOT NULL AND stock_location_quantity > 0').each do |is|
        puts "Processing ItemStock #{ is.id }"
        is2 = ItemStock.new
        is2.company = is.company
        is2.vendor = is.vendor
        is2.quantity = is.stock_location_quantity
        is2.location_id = is.stock_location_id
        is2.location_type = "StockLocation"
        is2.item_id = is.item_id
        result = is2.save
        if result != true
          raise "Could not save StockLocation because #{ is2.errors.messages }"
        end
      end
    end
    


      
  end

  def down
  end
end
