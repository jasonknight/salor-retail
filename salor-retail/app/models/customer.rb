# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Customer < ActiveRecord::Base
  # {START}
  include SalorScope
  include SalorModel
  include SalorBase
  has_one :loyalty_card
  belongs_to :vendor
  has_many :orders
  has_many :notes, :as => :notable, :order => "id desc"
  accepts_nested_attributes_for :notes, :reject_if => lambda {|a| a[:body].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :loyalty_card
  before_create :set_model_owner

  def set_sku
    self.sku = "#{self.company_name}#{self.first_name}#{self.last_name}".gsub(/[^a-zA-Z0-9]+/,'')
  end
  def full_name
    self.first_name = 'NotSet' if self.first_name.blank?
    
    if not self.company_name.blank? then
      return "#{self.company_name} | #{self.first_name} #{self.last_name}"
    else
      return "#{self.first_name} #{self.last_name}"
    end
    return "UnspecifiedError"
  end
  def to_json
    a = {
      :first_name => self.first_name,
      :last_name => self.last_name,
      :company_name => self.company_name,
      :sku => self.loyalty_card.sku,
      :points => self.loyalty_card.points
    }.to_json
  end
  def json_attrs
    a = {
      :name => self.full_name,
      :first_name => self.first_name,
      :last_name => self.last_name,
      :company_name => self.company_name,
      :sku => self.loyalty_card.sku,
      :points => self.loyalty_card.points,
      :id => self.id
    }
  end
  def loyalty_card_sku=(sku)
    if not self.loyalty_card then
      lc = LoyaltyCard.find_by_sku sku
      if not lc then
        lc = LoyaltyCard.new(:sku => sku)
      end
      self.loyalty_card = lc
    else
      self.loyalty_card.update_attribute(:sku, sku)
    end
  end
  def loyalty_card_points=(points)
    if not self.loyalty_card then
      lc = LoyaltyCard.new(:sku => rand(1000001),:points => points)
      self.loyalty_card = lc
    else
      self.loyalty_card.update_attribute(:points, points)
    end
  end
  def set_loyalty_card=(lc)
    self.loyalty_card.update_attributes(lc)
  end

  #
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
  # {END}
end
