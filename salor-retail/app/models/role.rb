# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Role < ActiveRecord::Base
  include SalorScope
  include SalorBase
  
  belongs_to :vendor
  belongs_to :company
  has_and_belongs_to_many :users
  
  validates_presence_of :vendor_id, :company_id
  
  # This is a role black list, if it isn't here
  # it means they can do it. Only put roles here
  # that the user cannot do, this should be over-
  # ridden by actual roles on the model.
  CANNOTDO = {
    :stockboy => [
      :any_orders,
      :any_users,
      :any_discounts,
      :any_current_registers,
      :any_tax_profiles,
      :any_customers,
      :any_actions,
      :any_actions,
      :any_buttons,
      :any_transaction_tags,
      :any_tender_methods,
      :any_sale_types,
      :any_invoice_blurbs,
      :any_countries,
      :edit_vendors,
      :new_vendors,
      :create_vendors,
      :update_vendors,
      :destroy_vendors,
      :edit_stock_locations,
      :edit_transaction_tags,
      :manager,
      :head_cashier,
      :cashier,
      :clear_orders,
      :destroy_order_items,
      :report_day_orders,
      :show_reports,
      :show_invoice_blurbs,
      :show_buttons,
      :show_invoice_notes,
      :show_sale_types,
      :show_countries,
      :show_tender_methods,
      :show_actions,
      :index_transaction_tags,
      :index_users,
      :create_discounts,
      :update_discounts,
      :edit_discounts,
      :destroy_discounts,
      :index_discounts,
      :show_tax_profiles
    ],
    :head_cashier => [
      :index_transaction_tags,
      :show_reports,
      :show_tender_methods,
      :any_shippers,
      :any_shipments,
      :any_categories,
      :any_buttons,
      :any_actions,
      :any_locations,
      :any_discounts,
      :any_shipment_items,
      :any_users,
      :create_transaction_tags,
      :create_tender_methods,
      :edit_tender_methods,
      :edit_current_registers,
      :destroy_items,
      :any_tax_profiles,
      :new_items,
      :edit_vendors,
      :new_vendors,
      :create_vendors,
      :update_vendors,
      :destroy_vendors,
      :destroy_current_registers,
      :edit_stock_locations,
      :edit_transaction_tags,
      :stockboy,
      :manager,
      :clear_orders,
      :report_day_orders,
      :show_invoice_blurbs,
      :show_invoice_notes
    ],
    :cashier => [
      :destroy_orders, # except their own orders
      :any_shippers,
      :any_shipments,
      :any_users,
      :any_categories,
      :any_buttons,
      :any_actions,
      :any_locations,
      :any_discounts,
      :any_shipment_items,
      :any_tax_profiles,
      :destroy_items,
      :new_items,
      :edit_vendors,
      :new_vendors,
      :index_vendors,
      :create_vendors,
      :update_vendors,
      :destroy_vendors,
      :new_current_registers,
      :edit_current_registers,
      :update_current_registers,
      :create_current_registers,
      :destroy_current_registers,
      :head_cashier,
      :edit_stock_locations,
      :edit_transaction_tags,
      :stockboy,
      :manager,
      :clear_orders,
      :destroy_order_items,
      :change_prices,
      :create_transaction_tags,
      :create_tender_methods,
      :edit_tender_methods,
      :show_reports,
      :show_invoice_blurbs,
      :show_buttons,
      :show_invoice_notes,
      :show_sale_types,
      :show_countries,
      :show_tender_methods,
      :show_actions,
      :index_transaction_tags,
      :index_users,
      :index_shippers,
      :index_shipments,
      :create_discounts,
      :update_discounts,
      :edit_discounts,
      :destroy_discounts,
      :index_discounts,
      :index_broken_items,
      :show_tax_profiles
    ],
    :assistant => [
      :anything
    ]
  }
end
