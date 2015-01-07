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
  
  def self.find_by_percentage(perc, vendor)
    perc = perc.to_s.gsub(",", ".")
    lower = perc.to_f - 0.2
    upper = perc.to_f + 0.2
    tps = vendor.tax_profiles.visible.where("value between #{ lower } and #{ upper }")
    return tps.first
  end
  
  def set_sku
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
end
