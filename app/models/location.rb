# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Location < ActiveRecord::Base
	include SalorScope
	include SalorBase
  include SalorModel
	belongs_to :vendor
	has_many :items, :conditions => "items.behavior = 'normal'"
	has_many :shipment_items
	has_many :discounts
	scope :applies, lambda {|t| where(:applies_to => t)}
end
