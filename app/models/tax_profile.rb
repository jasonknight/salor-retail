# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class TaxProfile < ActiveRecord::Base
	include SalorScope
  include SalorModel
  include SalorBase
  has_many :items
  has_many :order_items
  belongs_to :user
  before_create :set_model_owner
  validates_presence_of :name,:value
  def set_sku
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
  def value=(v)
    v = v.gsub(',','.').to_f if v.class == String and v.include?(',')
    write_attribute(:value,v)
    self.connection.execute("update items set tax_profile_amount = '#{v}' where tax_profile_id = '#{self.id}'")
  end
end
