# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Customer < ActiveRecord::Base

  include SalorScope
  include SalorBase
  
  has_many :loyalty_cards
  belongs_to :vendor
  belongs_to :company  
  has_many :orders
  has_many :notes, :as => :notable, :order => "id desc"
  
  validates_presence_of :company_id
  
  after_save :set_loyalty_card_relations
  
  
  accepts_nested_attributes_for :notes, :reject_if => lambda {|a| a[:body].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :loyalty_cards, :reject_if => proc { |attrs| attrs['sku'].blank? }
  
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
  def self.csv_headers
    return [:class, :id, :vendor_id, :company_name,:first_name, :last_name,:email,:telephone, :cellphone,:tax_number,:street1,:street2,:city, :postalcode, :state,:country, :loyalty_card_sku]
  end
  

  def to_csv(headers=nil)
    headers = Customer.csv_headers if headers.nil?
    values = []
    headers.each do |h|
      values << self.send(h)
    end
    return values.join("\t")
  end
  
  def set_sku
    self.sku = "#{self.company_name}#{self.first_name}#{self.last_name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
  # This is for the upload facility, changing a single loyalty card
  def loyalty_card_sku
    self.loyalty_cards.first.sku
  end
  def loyalty_card_sku=(s)
    self.loyalty_cards.first.update_attribute :sku, s
  end

  def full_name    
    if not self.company_name.blank? then
      return "#{self.company_name} | #{self.first_name} #{self.last_name}"
    else
      return "#{self.first_name} #{self.last_name}"
    end
  end
  
#   def to_json
#     a = {
#       :first_name => self.first_name,
#       :last_name => self.last_name,
#       :company_name => self.company_name,
#       :sku => self.loyalty_card.sku,
#       :points => self.loyalty_card.points
#     }.to_json
#   end
#   
  def json_attrs
    lc = self.loyalty_cards.visible.last
    sku = lc.sku if lc
    points = lc.points if lc
    a = {
      :name => self.full_name,
      :first_name => self.first_name,
      :last_name => self.last_name,
      :company_name => self.company_name,
      :sku => sku,
      :points => points,
      :id => self.id
    }
  end
  
#   def set_loyalty_card=(params)
#     sku = params['sku'].gsub(" ", "")
#     points = params['points']
#     lc = self.loyalty_card
#     if lc
#       lc.sku = sku
#       lc.points = points
#       lc.save
#     elsif not sku.blank?
#       lc = LoyaltyCard.new
#       lc.customer = self
#       lc.vendor = self.vendor
#       lc.company = self.company
#     end
#   end

  def get_item_statistics
    item = Hash.new
    orders = self.orders
    orders.each do |o|
      o.order_items.each do |oi|
        if item.has_key? oi.sku
          item[oi.sku][:count] += oi.quantity 
        else
          item[oi.sku] = {:name => oi.item.name, :count => oi.quantity, :sku => oi.sku}
        end
      end
    end 
    return item.sort { |x,y| y[1][:count] <=> x[1][:count] }
  end
  
  def hide(by)
    self.loyalty_cards.update_all :hidden => true, :hidden_by => by, :hidden_at => Time.now
    self.hidden = true
    self.hidden_by = by
    self.hidden_at = Time.now
    self.save
  end
  
  def set_loyalty_card_relations
    self.loyalty_cards.update_all :vendor_id => self.vendor, :company_id => self.company
  end
  
end
