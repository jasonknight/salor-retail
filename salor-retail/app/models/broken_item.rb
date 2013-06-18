# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class BrokenItem < ActiveRecord::Base
  include SalorScope
  include SalorBase
  include SalorModel
  belongs_to :vendor
  belongs_to :shipper
  after_create :decrement_item_quantity
  def decrement_item_quantity
    if item and not self.is_shipment_item then
      item = Item.scopied.find_by_sku self.sku
      item.quantity -= self.quantity
      item.save
    end
  end
  def owner
    if self.owner_type == 'User' then
      return User.where(["id = ?", self.owner_id]).first
    else
      return Employee.where(["id = ?", self.owner_id]).first
    end
  end
  
  def item
    if self.is_shipment_item then
      return ShipmentItem.scopied.find_by_sku(self.sku)
    end
    return Item.scopied.find_by_sku(self.sku)
  end
end
