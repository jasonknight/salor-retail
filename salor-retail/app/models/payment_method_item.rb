# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethodItem < ActiveRecord::Base
  include SalorBase
  include SalorScope
  belongs_to :order
  belongs_to :vendor
  belongs_to :company
  belongs_to :payment_method
  belongs_to :user
  belongs_to :drawer
  belongs_to :cash_register
  
  monetize :amount_cents, :allow_nil => true
  
  validates_presence_of :order_id
  validates_presence_of :company_id
  validates_presence_of :vendor_id
  validates_presence_of :user_id
  validates_presence_of :drawer_id
  validates_presence_of :payment_method_id
  validates_presence_of :cash_register_id
  
  def payment_method_id=(pmid)
    log_action "payment_method_id=() called"
    # called from orders/print
    
    pm = self.vendor.payment_methods.visible.find_by_id(pmid)
    
    if self.unpaid != true
      log_action "payment_method_id=(): we only allow changing unpaid to something else. returning"
      return
    end
    
    self.paid = true
    self.paid_at = Time.now
    self.is_unpaid = nil
    self.save!
    
    o = self.order
    o.paid = true
    o.paid_at = Time.now
    o.is_unpaid = nil
    o.save!
    
    o.order_items.update_all :paid => true, :paid_at => Time.now, :is_unpaid => nil
    
    if pm.cash
      drawer = self.drawer
      
      # create drawer transaction
      dt = DrawerTransaction.new
      dt.company = self.company
      dt.vendor = self.vendor
      dt.drawer = drawer
      dt.user = self.user
      dt.amount = self.amount
      dt.complete_order = true
      dt.drawer_amount = self.drawer.amount
      dt.cash_register = self.cash_register
      dt.save!
      
      # add to drawer amount
      drawer.amount += self.amount
      drawer.save!
    end

    write_attribute :payment_method_id, pmid
  end
end
