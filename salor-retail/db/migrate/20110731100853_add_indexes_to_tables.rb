class AddIndexesToTables < ActiveRecord::Migration
  def self.up
    add_index :actions, :vendor_id
    add_index :actions, :user_id
    add_index :cash_registers, :vendor_id
    add_index :cash_register_dailies, :cash_register_id
    add_index :cash_register_dailies, :employee_id
    add_index :cash_register_dailies, :user_id
    add_index :categories, :vendor_id
    add_index :configurations, :vendor_id
    add_index :customers, :vendor_id
    add_index :discounts, :vendor_id
    add_index :discounts, :category_id
    add_index :discounts, :location_id
    add_index :discounts_orders, [:order_id, :discount_id]
    add_index :discounts_order_items, [:order_item_id, :discount_id]
    add_index :drawers, :owner_id
    add_index :drawer_transactions, :drawer_id
    add_index :employees, :user_id
    add_index :employees, :vendor_id
    add_index :employees_roles, [:employee_id, :role_id]
    add_index :items, :vendor_id
    add_index :items, :location_id
    add_index :items, :category_id
    add_index :items, :tax_profile_id
    add_index :items, :item_type_id
    add_index :items, :coupon_type
    add_index :items, :part_id
    add_index :locations, :vendor_id
    add_index :loyalty_cards, :customer_id
    add_index :meta, :vendor_id
    add_index :meta, :crd_id
    add_index :meta, :order_id
    add_index :meta, :ownable_id
    add_index :meta, :cash_register_id
    add_index :notes, :notable_id
    add_index :notes, :user_id
    add_index :notes, :employee_id
    add_index :orders, :vendor_id
    add_index :orders, :user_id
    add_index :orders, :location_id
    add_index :orders, :employee_id
    add_index :orders, :cash_register_id
    add_index :orders, :customer_id
    add_index :orders, :cash_register_daily_id
    add_index :order_items, :order_id
    add_index :order_items, :item_id
    add_index :order_items, :tax_profile_id
    add_index :order_items, :item_type_id
    add_index :order_items, :category_id
    add_index :order_items, :location_id
    add_index :shipments, :receiver_id
    add_index :shipments, :shipper_id
    add_index :shipments, :user_id
    add_index :shipments, :employee_id
    add_index :shipments, :vendor_id
    add_index :shipment_items, :category_id
    add_index :shipment_items, :location_id
    add_index :shipment_items, :item_type_id
    add_index :shipment_items, :shipment_id
    add_index :shipment_items_stock_locations, [:shipment_item_id, :stock_location_id], :name => 'shipment_items_stock'
    add_index :shippers, :user_id
    add_index :shippers, :employee_id
    add_index :stock_locations, :vendor_id
    add_index :tax_profiles, :user_id
    add_index :vendors, :user_id
    add_index :vendor_printers, :vendor_id
    add_index :vendor_printers, :cash_register_id
  end

  def self.down
    remove_index :actions, :vendor_id
    remove_index :actions, :user_id
    remove_index :cash_registers, :vendor_id
    remove_index :cash_register_dailies, :cash_register_id
    remove_index :cash_register_dailies, :employee_id
    remove_index :cash_register_dailies, :user_id
    remove_index :categories, :vendor_id
    remove_index :configurations, :vendor_id
    remove_index :customers, :vendor_id
    remove_index :discounts, :vendor_id
    remove_index :discounts, :category_id
    remove_index :discounts, :location_id
    remove_index :discounts_orders, [:order_id, :discount_id]
    remove_index :discounts_order_items, [:order_item_id, :discount_id]
    remove_index :drawers, :owner_id
    remove_index :drawer_transactions, :drawer_id
    remove_index :employees, :user_id
    remove_index :employees, :vendor_id
    remove_index :employees_roles, [:employee_id, :role_id]
    remove_index :items, :vendor_id
    remove_index :items, :location_id
    remove_index :items, :category_id
    remove_index :items, :tax_profile_id
    remove_index :items, :item_type_id
    remove_index :items, :coupon_type
    remove_index :items, :part_id
    remove_index :locations, :vendor_id
    remove_index :loyalty_cards, :customer_id
    remove_index :meta, :vendor_id
    remove_index :meta, :crd_id
    remove_index :meta, :order_id
    remove_index :meta, :ownable_id
    remove_index :meta, :cash_register_id
    remove_index :notes, :notable_id
    remove_index :notes, :user_id
    remove_index :notes, :employee_id
    remove_index :orders, :vendor_id
    remove_index :orders, :user_id
    remove_index :orders, :location_id
    remove_index :orders, :employee_id
    remove_index :orders, :cash_register_id
    remove_index :orders, :customer_id
    remove_index :orders, :cash_register_daily_id
    remove_index :order_items, :order_id
    remove_index :order_items, :item_id
    remove_index :order_items, :tax_profile_id
    remove_index :order_items, :item_type_id
    remove_index :order_items, :category_id
    remove_index :order_items, :location_id
    remove_index :shipments, :receiver_id
    remove_index :shipments, :shipper_id
    remove_index :shipments, :user_id
    remove_index :shipments, :employee_id
    remove_index :shipments, :vendor_id
    remove_index :shipment_items, :category_id
    remove_index :shipment_items, :location_id
    remove_index :shipment_items, :item_type_id
    remove_index :shipment_items, :shipment_id
    remove_index :shipment_items_stock_locations, :name => 'shipment_items_stock'
    remove_index :shippers, :user_id
    remove_index :shippers, :employee_id
    remove_index :stock_locations, :vendor_id
    remove_index :tax_profiles, :user_id
    remove_index :vendors, :user_id
    remove_index :vendor_printers, :vendor_id
    remove_index :vendor_printers, :cash_register_id
  end
end
