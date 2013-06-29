class ChangeDefaults < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end
      
      if model.column_names.include? 'hidden' then
        puts "Changing :hidden column default value for #{model}"
        change_column_default t, :hidden, nil
      end
    end
      
    change_column_default :broken_items, :is_shipment_item, nil
    change_column_default :buttons, :is_buyback, nil
    change_column_default :drawer_transactions, :tag, nil
    change_column_default :drawer_transactions, :is_refund, nil
    
    change_column_default :cash_registers, :no_print, nil
    change_column_default :cash_registers, :salor_printer, nil
    change_column_default :items, :activated, nil
    change_column_default :items, :calculate_part_price, nil
    change_column_default :items, :is_gs1, nil
    change_column_default :items, :default_buyback, nil
    change_column_default :items, :weigh_compulsory, nil
    change_column_default :items, :ignore_qty, nil
    change_column_default :items, :hidden_by_distiller, nil
    change_column_default :items, :track_expiry, nil
    
    change_column_default :order_items, :activated, nil
    change_column_default :order_items, :total_is_locked, nil
    change_column_default :order_items, :tax_is_locked, nil
    change_column_default :order_items, :refunded, nil
    change_column_default :order_items, :discount_applied, nil
    change_column_default :order_items, :coupon_applied, nil
    change_column_default :order_items, :is_buyback, nil
    change_column_default :order_items, :weigh_compulsory, nil
    change_column_default :order_items, :no_inc, nil
    change_column_default :order_items, :action_applied, nil
    change_column_default :order_items, :tax_free, nil
    
    change_column_default :orders, :refunded, nil
    change_column_default :orders, :total_is_locked, nil
    change_column_default :orders, :tax_is_locked, nil
    change_column_default :orders, :subtotal_is_locked, nil
    change_column_default :orders, :buy_order, nil
    change_column_default :orders, :tax_free, nil
    change_column_default :orders, :is_proforma, nil
    change_column_default :orders, :unpaid_invoice, nil
    change_column_default :orders, :is_quote, nil
    
    change_column_default :shipment_items, :in_stock, nil
  end

  def down
  end
end

