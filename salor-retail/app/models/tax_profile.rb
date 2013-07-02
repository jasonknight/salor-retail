# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class TaxProfile < ActiveRecord::Base
	include SalorScope
  include SalorBase
  
  has_many :items
  has_many :order_items
  belongs_to :user
  belongs_to :vendor
  belongs_to :company
  
  validates_presence_of :name, :value, :letter
  
  def set_sku
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
end
