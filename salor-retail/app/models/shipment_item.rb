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
  
  def move_into_stock(q, locationstring)
    q = q.to_f
    item = self.vendor.items.visible.find_by_sku(self.sku)
    if item
      log_action "move_into_stock: An Item with sku #{ self.sku } already exists. Using this to add to it."
      locationclass = locationstring.split(':')[0].constantize
      locationid = locationstring.split(':')[1]
      location = locationclass.visible.where(:vendor_id => self.vendor_id, :company_id => self.company_id).find_by_id(locationid)
      
      existing_item_stock = location.item_stocks.visible.find_by_item_id(item.id)
      if existing_item_stock
        log_action "move_into_stock: Item #{ item.id } with sku #{ item.sku } already has an ItemStock #{ existing_item_stock.id }. Adding to it"
        if locationclass == Location
          existing_item_stock.location_quantity = existing_item_stock.location_quantity.to_f + q
        else
          existing_item_stock.stock_location_quantity = existing_item_stock.stock_location_quantity.to_f + q
        end
        existing_item_stock.save
      else
        # this method creates an ItemStock if not yet present. see item.rb
        log_action "move_into_stock: Item #{ item.id } with sku #{ item.sku } doesn't have yet an ItemStock. Creating one."
        item.set_quantity_with_stock(q, location)
      end
      
    else
      log_action "move_into_stock: No Item with sku #{ self.sku } exists yet. Creating one from ShipmentItem."
      normal_item_type = self.vendor.item_types.visible.find_by_behavior('normal')
      if normal_item_type.nil?
        raise "Need an ItemType with behavior normal for this action"
      end
      
      i = Item.new
      i.vendor = self.vendor
      i.company = self.company
      i.sku = self.sku
      i.tax_profile = self.tax_profile
      i.name = self.name
      i.item_type = normal_item_type
      
      result = i.save
      if result != true
        raise "Could not save Item because #{ i.errors.messages }"
      end
      i.set_quantity_with_stock(q)
      
    end
    
    self.in_stock_quantity = self.in_stock_quantity.to_f + q
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
