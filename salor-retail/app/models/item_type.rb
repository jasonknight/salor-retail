# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class ItemType < ActiveRecord::Base
	include SalorScope
  include SalorModel
  has_many :items
  has_many :order_items
  has_many :shipment_items
  def get_name
    return I18n.t("activerecord.models.item_type.#{self.behavior}")
  end
  def as_json(x=nil)
    return to_json(x)
  end
  def to_json(x=nil)
    obj = {
        :name => self.get_name,
        :id => self.id,
        :behavior => self.behavior
    }
    return obj
  end
end
