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
  
  
  accepts_nested_attributes_for :notes, :reject_if => lambda {|a| a[:body].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :loyalty_cards, :reject_if => proc { |attrs| attrs['sku'].blank? }
  
  
  def self.csv_headers
    return [:company_name,:first_name, :last_name,:email,:telephone, :cellphone,:tax_number,:street1,:street2,:city, :postalcode, :state,:country, :loyalty_card_sku]
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
  
end
