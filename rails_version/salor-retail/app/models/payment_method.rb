# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethod < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :vendor
  belongs_to :company
  has_many :payment_method_items
  
  validates_presence_of :vendor_id, :company_id, :name
  
  before_save :set_booleans_to_nil
  
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
  
  def set_booleans_to_nil
    self.cash = nil if self.respond_to? :cash and self.cash == false
    self.quote = nil if self.respond_to? :quote and self.quote == false
    self.unpaid = nil if self.respond_to? :unpaid and self.unpaid == false
    self.change = nil if self.respond_to? :change and self.change == false
  end
end
