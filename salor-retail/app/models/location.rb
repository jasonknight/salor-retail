# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Location < ActiveRecord::Base
	include SalorScope
	include SalorBase

	belongs_to :vendor
  belongs_to :company
  
	has_many :items, :conditions => "items.behavior = 'normal'"
	has_many :shipment_items
	has_many :discounts
  before_create :set_sku
	scope :applies, lambda {|t| where(:applies_to => t)}
  
  validates_presence_of :name
  
  def set_sku
    # This might cause issues down the line with a SAAS version so we need to make sure
    # that the request for a category by sku is scopied.
    # the reason we do it like this is for reproducibility across systems.
    # Note that this algorithm should not support special chars, so if you have a
    # category named stüff then the sku would come out: stff
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'') if self.sku.blank?
  end

end
