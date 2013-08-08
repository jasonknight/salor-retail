# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class LoyaltyCard < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :customer
  belongs_to :vendor
  belongs_to :company
  
  has_many :orders, :through => :customer
  
  validates_uniqueness_of :sku, :scope => :company_id
  validates_presence_of :sku
  

  
#   def customer_sku
#     log_action "customer_sku called"
#     csku = self.customer.sku if self.customer
#     if csku.blank? then
#       self.customer.set_sku
#       csku = self.customer.sku
#       self.customer.save
#     end
#     return csku
#   end
#   
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
  def json_attrs
    return {
      :sku => self.sku,
      :points => self.points,
      :customer_id => self.customer_id,
      :num_swipes => self.num_swipes,
      :id => self.id
    }
  end
end
