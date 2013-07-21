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
end
