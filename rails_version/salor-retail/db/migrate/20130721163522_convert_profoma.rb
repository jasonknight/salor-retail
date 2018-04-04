class ConvertProfoma < ActiveRecord::Migration
  def up
    # PMIs are queried by that on the day report, so we have to set it
    Vendor.connection.execute("UPDATE payment_method_items,orders SET payment_method_items.is_proforma = orders.is_proforma WHERE payment_method_items.order_id = orders.id")
    
    # PMIs are queried by that on the day report, so we have to set it
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.is_proforma = orders.is_proforma WHERE order_items.order_id = orders.id")
    
    # old system didn't set user_id for OIs, but it is queried now, so we have to fix that
    Vendor.connection.execute("UPDATE order_items,orders SET order_items.user_id = orders.user_id WHERE order_items.order_id = orders.id")
    

    
    Vendor.all.each do |v|
      ztp = v.tax_profiles.visible.find_by_value(0)
      if ztp.nil?
        puts "WARNING: Vendor #{ v.id } does not have a zero tax profile. This is necessary for proforma invoices. Please fix this manually."
        next
      end
      
      # proforma invoices are always 0 tax, since it is similar to a gift card in that it it just a virtual issued payment method. we pay taxes only once, on the final invoice. we would pay taxes twice if a nonzero tax would be on the proforma invoice.
      Vendor.connection.execute("UPDATE order_items SET tax_amount_cents = 0, tax = 0, tax_profile_id = #{ ztp.id } WHERE is_proforma IS TRUE")
      Vendor.connection.execute("UPDATE orders SET tax_amount_cents = 0, tax = 0, tax_profile_id = #{ ztp.id } WHERE is_proforma IS TRUE")
      
      
      # DMYACONTO OrderItems now have the new ItemType aconto. this is for the day report queries
      aconto_it = v.item_types.visible.find_by_behavior("aconto")
      v.order_items.visible.paid.where(:sku => 'DMYACONTO').each do |oi|
        oi.item_type = aconto_it
        oi.behavior = "aconto"
        oi.is_buyback = nil # the old system set this as buyback, but that is something entirely different now.
        res = oi.save
        raise "Cannot save OI because #{ oi.errors.messages }" unless res == true
      end
    end
  end

  def down
  end
end
