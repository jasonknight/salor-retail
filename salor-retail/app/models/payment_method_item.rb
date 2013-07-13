# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethodItem < ActiveRecord::Base
  belongs_to :order
  belongs_to :vendor
  belongs_to :company
  belongs_to :payment_method
  belongs_to :user
  belongs_to :drawer
  belongs_to :cash_register
  
  monetize :amount_cents, :allow_nil => true
  
  include SalorBase
  include SalorScope
end
