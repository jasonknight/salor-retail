# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethod < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :vendor
  belongs_to :company
  has_many :payment_method_items
  
  before_save :set_to_nil
  
  def set_to_nil
    self.cash = nil if self.cash == false
    self.quote = nil if self.quote == false
    self.unpaid = nil if self.unpaid == false
    self.change = nil if self.change == false
  end
end
