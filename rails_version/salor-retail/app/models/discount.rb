# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Discount < ActiveRecord::Base
  include SalorBase
  include SalorScope
  #include ActionView::Helpers::NumberHelper

  belongs_to :vendor
  belongs_to :location
  belongs_to :company
  belongs_to :category
  has_and_belongs_to_many :order_items
  has_and_belongs_to_many :orders
  
  validates_presence_of :name
  validates_presence_of :vendor_id, :company_id
  
  APPLIES = [
    [I18n.t("activerecord.models.vendor.one"),"Vendor"],
    [I18n.t("activerecord.models.location.one"),"Location"],
    [I18n.t("activerecord.models.category.one"),"Category"],
    [I18n.t("activerecord.models.item.one"),"Item"]
  ]
  TYPES = [
    {:text => I18n.t('views.forms.percent_off'), :value => 'percent'},
    {:text => I18n.t('views.forms.fixed_amount_off'), :value => 'fixed'}, 
  ]
  validates_presence_of :name
  after_save :refresh_discounts
  after_update :refresh_discounts
  after_destroy :refresh_discounts
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
  def category_sku
    return self.category.sku if self.category
  end
  def category_sku=(str)
    c = Category.scopied.find_by_sku(str)
    self.category = c if c
  end
  def location_sku
    return self.location.sku if self.location
  end
  def location_sku=(str)
    d = Location.scopied.find_by_sku(str)
    self.location = d if d
  end
  def set_sku
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
  def refresh_discounts
    
  end
  def amount=(a)
    a = a.to_s.gsub(',','.').to_f
    write_attribute(:amount,a)
  end
  def types_display
    TYPES.each do |type|
      return type[:text] if self.amount_type == type[:value]
    end
    return self.amount_type
  end
  
  def item
    if self.applies_to == 'Item' then
      return self.vendor.items.find_by_sku(self.item_sku)
    end
  end
    # WTF? I have no idea what this is even doing here...
  # REMOVE ME SOON
  def simulate(item)
    price = item.base_price
    damount = 0
    if self.amount_type == 'percent' then
          d = self.amount / 100
          damount += (price * d)
    else
      damount += self.amount
    end
    item.base_price = price - damount
    return item
  end
  
#   def name_for_receipt
#     if self.amount_type == 'percent'
#       amount = number_to_percentage(self.amount, :locale => self.vendor.region)
#     else
#       amount = number_to_currency(self.amount, :locale => self.vendor.region)
#     end
#     I18n.t('printr.order_receipt.discount') + ' ' + self.name + ' ' + amount
#   end
end
