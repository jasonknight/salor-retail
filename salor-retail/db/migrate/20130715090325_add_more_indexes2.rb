class AddMoreIndexes2 < ActiveRecord::Migration
  def up
    drop_table :cash_register_dailies
    add_index :cash_registers, :company_id
    add_index :cash_registers, :hidden
    
    add_index :categories, :company_id
    add_index :categories, :hidden
    
    add_index :customers, :company_id
    add_index :customers, :hidden
    
    add_index :discounts, :company_id
    add_index :discounts, :hidden
    add_index :discounts, :sku
    add_index :discounts, :item_sku
    
    drop_table :discounts_orders
    
    add_index :drawer_transactions, :company_id
    add_index :drawer_transactions, :vendor_id
    add_index :drawer_transactions, :user_id
    add_index :drawer_transactions, :complete_order
    add_index :drawer_transactions, :hidden
    add_index :drawer_transactions, :refund
    
    add_index :item_shippers, :company_id
    add_index :item_shippers, :vendor_id
    add_index :item_shippers, :hidden
    
    add_index :item_stocks, :company_id
    add_index :item_stocks, :vendor_id
    add_index :item_stocks, :hidden
    
    add_index :items, :company_id
    add_index :items, :hidden
    
    add_index :locations, :company_id
    add_index :locations, :hidden
    
    add_index :loyalty_cards, :company_id
    add_index :loyalty_cards, :vendor_id
    add_index :loyalty_cards, :hidden
    
    add_index :order_items, :vendor_id
    add_index :order_items, :company_id
    add_index :order_items, :hidden
    add_index :order_items, :refunded
    add_index :order_items, :drawer_id
    add_index :order_items, :no_inc
    add_index :order_items, :user_id
    
    add_index :orders, :company_id
    add_index :orders, :hidden
    add_index :orders, :drawer_id
    add_index :orders, :paid
    
    add_index :payment_method_items, :company_id
    add_index :payment_method_items, :vendor_id
    add_index :payment_method_items, :hidden
    add_index :payment_method_items, :cash
    add_index :payment_method_items, :change
    add_index :payment_method_items, :user_id
    add_index :payment_method_items, :drawer_id
    add_index :payment_method_items, :payment_method_id
    add_index :payment_method_items, :cash_register_id
    add_index :payment_method_items, :refund
    
    add_index :shipment_items, :vendor_id
    add_index :shipment_items, :company_id
    add_index :shipment_items, :hidden
    
    add_index :shipments, :company_id
    add_index :shipments, :hidden
    
    
  end

  def down
  end
end
