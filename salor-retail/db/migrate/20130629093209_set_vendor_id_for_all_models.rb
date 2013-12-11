class SetVendorIdForAllModels < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end

      vendor_id = Order.last.vendor_id if Order.last
      vendor_id ||= Vendor.first.id if Vendor.first
      if vendor_id
        if model.column_names.include? 'vendor_id' then
          puts "Setting #{ t } to vendor_id #{ vendor_id }"
          model.connection.execute("UPDATE #{ t } SET vendor_id=#{ vendor_id };")
        end
      end
    end
  end
  
  def down
  end
end
