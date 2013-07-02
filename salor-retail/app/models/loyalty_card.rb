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
  
  validates_uniqueness_of :sku
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
