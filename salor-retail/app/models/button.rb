# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Button < ActiveRecord::Base
  include SalorScope
  include SalorBase


  belongs_to :category
  belongs_to :vendor
  belongs_to :company
  before_save :set_flags
  
  validates_presence_of :vendor_id, :company_id, :name, :sku, :category_id
  
  
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
  def category_sku=(sku)
    self.category = Category.where(:sku => sku).first
  end
  
  def category_sku
    return self.category.sku if self.category
  end
  
  def set_flags
    i = Item.find_by_sku self.sku
    self.is_buyback = true if i and i.default_buyback
  end
  
  def self.sort(buttons,type)
    type.map! {|t| t.to_i}
    buttons.each do |b|
      b.position ||= 0
      b.update_attribute :position, type.index(b.id) + 1 if type.index(b.id)
    end
    return buttons
  end
end
