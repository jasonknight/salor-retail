# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class ShipmentItem < ActiveRecord::Base
	include SalorScope
  include SalorBase

  belongs_to :shipment
  belongs_to :category
  belongs_to :location
  belongs_to :item_type
  monetize :price_cents
  monetize :purchase_price_cents
  has_and_belongs_to_many :stock_locations
  
  
  def set_stock_location_ids=(ids) 
    if ids.class == String then
      ids = [ids.to_i]
    end
    self.stock_location_ids = ids
  end
end
