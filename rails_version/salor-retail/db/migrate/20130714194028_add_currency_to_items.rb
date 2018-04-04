class AddCurrencyToItems < ActiveRecord::Migration
  def change
    remove_column :broken_items, :price_currency
    
    remove_column :drawer_transactions, :amount_currency
    remove_column :drawer_transactions, :drawer_amount_currency
    
    remove_column :drawers, :amount_currency
    
    remove_column :items, :price_currency
    remove_column :items, :gift_card_amount_currency
    remove_column :items, :purchase_price_currency
    remove_column :items, :buy_price_currency
    remove_column :items, :manufacturer_price_currency
    
    remove_column :order_items, :price_currency
    remove_column :order_items, :gift_card_amount_currency
    remove_column :order_items, :tax_amount_currency
    remove_column :order_items, :coupon_amount_currency
    remove_column :order_items, :discount_amount_currency
    remove_column :order_items, :rebate_amount_currency
    remove_column :order_items, :total_currency
    
    remove_column :orders, :total_currency
    remove_column :orders, :tax_amount_currency
    remove_column :orders, :cash_currency
    remove_column :orders, :lc_amount_currency
    remove_column :orders, :change_currency
    remove_column :orders, :payment_total_currency
    remove_column :orders, :noncash_currency
    remove_column :orders, :rebate_amount_currency
    
    remove_column :payment_method_items, :amount_currency
    
    remove_column :shipment_items, :price_currency
    remove_column :shipment_items, :purchase_price_currency
    
    remove_column :shipments, :price_currency
    
    add_column :vendors, :currency, :string
    add_column :broken_items, :currency, :string
    add_column :drawer_transactions, :currency, :string
    add_column :drawers, :currency, :string
    add_column :items, :currency, :string
    add_column :order_items, :currency, :string
    add_column :orders, :currency, :string
    add_column :payment_method_items, :currency, :string
    add_column :shipment_items, :currency, :string
    add_column :shipments, :currency, :string
  end
end
