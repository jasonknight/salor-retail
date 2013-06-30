class CopyConfigurationIntoVendor < ActiveRecord::Migration
  def up
    attrs = ['lp_per_dollar', 'dollar_per_lp', 'address', 'telephone', 'receipt_blurb', 'pagination', 'stylesheets', 'cash_drawer', 'open_cash_drawer', 'last_wholesaler_check', 'csv_imports', 'csv_imports_url', 'items_view_list', 'url', 'salor_printer', 'receipt_blurb_footer', 'calculate_tax', 'license_accepted', 'csv_categories', 'csv_buttons', 'csv_discounts', 'csv_customers', 'csv_loyalty_cards', 'invoice_blurb', 'invoice_blurb_footer']
    
    v = Order.last.vendor if Order.last
    v ||= Vendor.first
    
    attrs.each do |a|
      val = Vendor.connection.execute("SELECT #{ a } FROM salor_configurations WHERE vendor_id=1;").to_a.flatten.first
      v.update_attribute a, val
    end
  end

  def down
  end
end
