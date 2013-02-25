# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethod < ActiveRecord::Base
  belongs_to :order
  before_save :process
  include SalorModel
  include SalorBase
  def self.types_list
    types = []
    pmx = I18n.t("system.payment_external_types").split(',')
    pmi = I18n.t("system.payment_internal_types").split(',')
    tms = TenderMethod.scopied.all
     i = 0
    pmi.each do |p|
      types << [pmx[i],p]
      i  = i + 1
    end
    tms.each do |tm|
      types << [tm.name,tm.internal_type]
    end
    return types
  end
  def self.total(type)
    ttl = 0.0
    Orders.scopied.each do |o| 
      o.payment_methods.each do |pm|
        if pm.internal_type.to_sym == type.to_sym then
          ttl += pm.amount
        end
      end
    end
    return ttl
  end
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
    self.vendor_id = $Vendor.id
  end
end
