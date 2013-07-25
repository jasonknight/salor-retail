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
  belongs_to :vendor
  belongs_to :company
  belongs_to :item_type
  belongs_to :tax_profile
  
  monetize :price_cents
  monetize :total_cents
  monetize :purchase_price_cents
  monetize :purchase_price_total_cents
  
  has_and_belongs_to_many :stock_locations
  
  
  def set_stock_location_ids=(ids) 
    if ids.class == String then
      ids = [ids.to_i]
    end
    self.stock_location_ids = ids
  end
  
  def calculate_totals
    self.total_cents = self.price_cents * self.quantity
    self.purchase_price_total_cents = self.purchase_price_cents * self.quantity
    self.save
  end
  
  def hide(by)
    self.hidden = true
    self.hidden_by = by
    self.hidden_at = Time.now
    self.save
  end
  
  def to_json
    json = {
      :id => self.id,
      :name => self.name,
      :category_id => self.category_id,
      :location_id => self.location_id,
      :item_type_id => self.item_type_id,
      :sku => self.sku,
      :shipment_id => self.shipment_id,
      :quantity => self.quantity,
      :price => self.price.to_f,
      :total => self.total.to_f,
      :purchase_price => self.purchase_price.to_f,
      :purchase_price_total => self.purchase_price_total.to_f,
      :tax_profile_id => self.tax_profile_id,
      :hidden => self.hidden
    }.to_json
  end
  
end
