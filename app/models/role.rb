# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Role < ActiveRecord::Base
	include SalorScope
  include SalorModel
  include SalorBase
  has_and_belongs_to_many :employees
  # This is a role black list, if it isn't here
  # it means they can do it. Only put roles here
  # that the user cannot do, this should be over-
  # ridden by actual roles on the model.
  CANNOTDO = {
    :stockboy => [
      :any_orders,
      :any_employees,
      :any_discounts,
      :any_cash_registers,
      :any_tax_profiles,
      :any_customers,
      :any_actions,
      :any_actions,
      :any_buttons,
      :any_transaction_tags,
      :any_tender_methods,
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
      :report_day_orders
    ],
    :head_cashier => [
      :any_shippers,
      :any_shipments,
      :any_categories,
      :any_buttons,
      :any_actions,
      :any_locations,
      :any_discounts,
      :any_shipment_items,
      :any_employees,
      :create_transaction_tags,
      :create_tender_methods,
      :edit_tender_methods,
      :destroy_items,
      :any_tax_profiles,
      :new_items,
      :edit_vendors,
      :new_vendors,
      :create_vendors,
      :update_vendors,
      :destroy_vendors,
      :edit_stock_locations,
      :edit_transaction_tags,
      :stockboy,
      :manager,
      :clear_orders,
      :report_day_orders
    ],
    :cashier => [
      :destroy_orders, # except their own orders
      :any_shippers,
      :any_shipments,
      :any_employees,
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
      :new_cash_registers,
      :edit_cash_registers,
      :update_cash_registers,
      :create_cash_registers,
      :destroy_cash_registers,
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
      :edit_tender_methods
    ],
    :employee => [
      :anything,
      :edit_tender_methods,
      :edit_items,
      :show_orders,
      :index_customers,
      :report_day_orders
    ]
  }
end
