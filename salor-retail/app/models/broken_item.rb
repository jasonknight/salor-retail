# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class BrokenItem < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :vendor
  belongs_to :company
  belongs_to :shipper

  monetize :price_cents, :allow_nil => true
  
  after_create :decrement_item_quantity
  
  validates_presence_of :sku
  validates_presence_of :quantity
  validates_presence_of :vendor_id, :company_id
  
  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end

  def decrement_item_quantity
    if self.item and not self.is_shipment_item then
      item = self.vendor.items.visible.find_by_sku(self.sku)
      item.quantity -= self.quantity
      item.save
    end
  end
  
  def item
    if self.is_shipment_item then
      return self.vendor.shipment_items.visible.find_by_sku(self.sku)
    else
      return self.vendor.items.visible.find_by_sku(self.sku)
    end
  end
end
