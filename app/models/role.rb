# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
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
      :change_prices
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
      :edit_tender_methods,
      :edit_items,
      :show_orders,
      :index_customers,
      :report_day_orders
    ]
  }
end
