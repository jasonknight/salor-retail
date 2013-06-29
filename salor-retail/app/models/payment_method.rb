# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethod < ActiveRecord::Base
  belongs_to :order
  belongs_to :vendor
  before_save :process

  include SalorBase
  
  def process
    pmx = I18n.t("system.payment_external_types").split(',')
    pmi = I18n.t("system.payment_internal_types").split(',')
    i = 0
    pmi.each do |p|
      if p == self.internal_type then
        self.name = pmx[i]
      end
      i = i + 1
    end
  end
end
