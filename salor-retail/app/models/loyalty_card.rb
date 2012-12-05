# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class LoyaltyCard < ActiveRecord::Base
	include SalorScope
	include SalorBase
  include SalorModel
  belongs_to :customer
  has_many :orders, :through => :customer
  before_save :clean_model
  before_update :clean_model
  validate :validify
  def validify
    clean_model
  end
  def clean_model
    self.sku = self.sku.gsub(' ','')
  end
  def customer_sku
    csku = self.customer.sku if self.customer
    if csku.blank? then
      self.customer.set_sku
      csku = self.customer.sku
      self.customer.save
    end
    return csku
  end
  def json_attrs
    return {
      :sku => self.sku,
      :points => self.points,
      :customer_id => self.customer_id,
      :num_swipes => self.num_swipes,
      :id => self.id
    }
  end
end
