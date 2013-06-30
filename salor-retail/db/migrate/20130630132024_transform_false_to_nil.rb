class TransformFalseToNil < ActiveRecord::Migration
  def up
    puts "Processing orders..."
    Order.connection.execute("UPDATE orders SET is_proforma=NULL WHERE is_proforma=0;")
    Order.connection.execute("UPDATE orders SET unpaid_invoice=NULL WHERE unpaid_invoice=0;")
    Order.connection.execute("UPDATE orders SET is_quote=NULL WHERE is_quote=0;")
    Order.connection.execute("UPDATE orders SET tax_free=NULL WHERE tax_free=0;")
    Order.connection.execute("UPDATE orders SET buy_order=NULL WHERE buy_order=0;")
    Order.connection.execute("UPDATE orders SET refunded=NULL WHERE refunded=0;")
    Order.connection.execute("UPDATE orders SET paid=NULL WHERE paid=0;")
    Order.connection.execute("UPDATE orders SET hidden=NULL WHERE hidden=0;")
    
    puts "Processing order_items..."
    OrderItem.connection.execute("UPDATE order_items SET activated=NULL WHERE activated=0;")
    OrderItem.connection.execute("UPDATE order_items SET refunded=NULL WHERE refunded=0;")
    OrderItem.connection.execute("UPDATE order_items SET discount_applied=NULL WHERE discount_applied=0;")
    OrderItem.connection.execute("UPDATE order_items SET coupon_applied=NULL WHERE coupon_applied=0;")
    OrderItem.connection.execute("UPDATE order_items SET is_buyback=NULL WHERE is_buyback=0;")
    OrderItem.connection.execute("UPDATE order_items SET no_inc=NULL WHERE no_inc=0;")
    OrderItem.connection.execute("UPDATE order_items SET weigh_compulsory=NULL WHERE weigh_compulsory=0;")
    OrderItem.connection.execute("UPDATE order_items SET action_applied=NULL WHERE action_applied=0;")
    OrderItem.connection.execute("UPDATE order_items SET hidden=NULL WHERE hidden=0;")
    OrderItem.connection.execute("UPDATE order_items SET tax_free=NULL WHERE tax_free=0;")
    
    puts "Processing items..."
    Item.connection.execute("UPDATE items SET activated=NULL WHERE activated=0;")
    Item.connection.execute("UPDATE items SET hidden=NULL WHERE hidden=0;")
    Item.connection.execute("UPDATE items SET calculate_part_price=NULL WHERE calculate_part_price=0;")
    Item.connection.execute("UPDATE items SET is_gs1=NULL WHERE is_gs1=0;")
    Item.connection.execute("UPDATE items SET default_buyback=NULL WHERE default_buyback=0;")
    Item.connection.execute("UPDATE items SET weigh_compulsory=NULL WHERE weigh_compulsory=0;")
    Item.connection.execute("UPDATE items SET ignore_qty=NULL WHERE ignore_qty=0;")
    Item.connection.execute("UPDATE items SET must_change_price=NULL WHERE must_change_price=0;")
    Item.connection.execute("UPDATE items SET hidden_by_distiller=NULL WHERE hidden_by_distiller=0;")
    Item.connection.execute("UPDATE items SET track_expiry=NULL WHERE track_expiry=0;")
    
    change_column_default :cash_registers, :big_buttons, nil
    change_column_default :cash_registers, :hide_discounts, nil
    change_column_default :drawer_transactions, :drawer_amount, nil
    
    change_column_default :items, :must_change_price, nil
    change_column_default :users, :js_keyboard, nil
    change_column_default :users, :last_path, nil
    
    change_column_default :vendors, :multi_currency, nil
    
    remove_column :cash_registers, :paylife
    remove_column :cash_registers, :bank_machine_path
    
    remove_column :categories, :eod_show
    remove_column :categories, :tag
    
    drop_table :errors
  end

  def down
  end
end
