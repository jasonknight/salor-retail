# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.


class Category < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :vendor
  belongs_to :company
  
  has_many :items
  has_many :shipment_items
  has_many :discounts
  has_many :buttons, :order => :position
  has_many :actions, :as => :model, :order => "weight asc"
  
  has_many :order_items
  before_create :set_sku
  
  validates_presence_of :name
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
  def set_sku
    # This might cause issues down the line with a SAAS version so we need to make sure
    # that the request for a category by sku is scopied.
    # the reason we do it like this is for reproducibility across systems.
    # Note that this algorithm should not support special chars, so if you have a
    # category named stüff then the sku would come out: stff
    self.sku = "#{self.name}".gsub(/[^a-zA-Z0-9]+/,'') if self.sku.blank?
  end
  
  def get_tag
    if not self.tag or self.tag == '' then
      return self.name.gsub(" ",'')
    end
    self.tag.gsub(' ','')
  end
  
	# We don't really call this function directly, it is called by @current_register.end_of_day_report, which
	# returns a hash that is merged with this one. This way, we delegate the reponsibilities up the chain
	# so that in the view, we can just call: hash = @current_register.end_of_day_report and then loop over the
	# key value pairs to make a pretty table
	def self.cats_report(drawer_id=nil)
	  cats_tags = {}
	  drawer_id = @current_user.get_drawer.id if drawer_id.nil?
	  Category.scopied.where(:eod_show => true).each do |category|  
      tag = category.get_tag
      category.order_items.where(:refunded => false,:created_at => Time.now.beginning_of_day..Time.now).joins(:order).where("`orders`.`drawer_id` = #{drawer_id}").each do |oi|
        cats_tags[tag] = 0 if cats_tags[tag].nil?
        cats_tags[tag] += oi.total if oi.order.paid == 1
      end
    end
    return cats_tags
	end
end
