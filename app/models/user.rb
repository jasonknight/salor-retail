# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class User < ActiveRecord::Base
	include SalorScope
	include SalorBase
	include SalorModel
  include UserEmployeeMethods
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable

  # Setup accessible (or protected) attributes for your model
  #attr_accessible :js_keyboard,:username, :language,:email, :password, :password_confirmation, :remember_me
  #attr_accessible :auth_code
  
  has_many :vendors
  has_many :employees
  has_many :orders
  has_many :tax_profiles
  has_many :cash_register_dailies
  has_many :items, :through => :vendors
  has_many :paylife_structs, :as => :owner
  has_one :meta, :as => :ownable
  has_one :drawer, :as => :owner
  has_many :drawer_transactions, :as => :owner
  has_many :shippers
  has_many :shipments
  def usage
    report = {}
    report[:vendors] = Vendor.scopied.count
    report[:items] = Item.where("name NOT LIKE 'DMY%'").scopied.count
    report[:dummy_items] = Item.where("name LIKE 'DMY%'").scopied.count
    report[:tax_profiles] = self.tax_profiles.count
    report[:orders] = 0
    report[:order_items] = 0
    report[:employees] = 0
    report[:registers] = 0
    Vendor.scopied.each do |vendor|
      report[:orders] += vendor.orders.count
      report[:order_items] += vendor.orders.each.inject(0) {|x,o| x+= o.order_items.visible.count}
      report[:employees] += vendor.employees.count
      report[:registers] += vendor.cash_registers.count
    end
    report[:shipment_items] = Shipment.scopied.each.inject(0) {|x,shipment| x += shipment.shipment_items.count}
    return report
  end
  
  def usage_totals(rep = nil)
    if rep.nil? then
      rep = self.usage
    end
    costs = AppConfig.config["costs"]
    total = 0.0
    costs.each do |k,v|
      total += rep[k.to_sym] * v
    end
    return total
  end
  
  def clean_slate
    vids = []
    self.vendors.each do |v|
      vids << v.id
      v.orders.each do |order|
        order.order_items.delete_all
        order.destroy
        v.discounts.each do |discount|
          discount.connection.execute("delete from discounts_orders where discount_id = #{discount.id}")
          discount.connection.execute("delete from discounts_order_items where discount_id = #{discount.id}")
        end
        v.shipments.each do |s|
          s.shipment_items.delete_all
          s.destroy
        end
      end
    end
    Item.connection.execute("delete from items where vendor_id in (#{vids.join(',')})")
    Item.connection.execute("delete from categories where vendor_id in (#{vids.join(',')})")
    Item.connection.execute("delete from locations where vendor_id in (#{vids.join(',')})")
    Item.connection.execute("delete from customers where vendor_id in (#{vids.join(',')})")
    Item.connection.execute("delete from buttons where vendor_id in (#{vids.join(',')})")
    Item.connection.execute("delete from employees where vendor_id in (#{vids.join(',')})")
  end
  
end
