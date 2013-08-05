# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Drawer < ActiveRecord::Base
  include SalorBase

  has_one :user
  belongs_to :company
  
  has_many :orders
  has_many :drawer_transactions
  
  validates_presence_of :company_id

  monetize :amount_cents, :allow_nil => true
  
  def to_json
    { :amount => self.amount.to_f }.to_json
  end
  
  def check_range(from=nil, to=nil)
    if from.class == String
      if from
        from = Date.parse(from).beginning_of_day
      else
        from = Time.now.beginning_of_day
      end
    end
    
    if from.class == String
      if to
        to = Date.parse(to).end_of_day
      elsif from.nil?
        to = Time.now.end_of_day
      else
        to = from.end_of_day
      end
    end
    
    tests = []
    
    dts = self.drawer_transactions.where(:created_at => from..to)
    return tests unless dts.any?
    
    drawer_amount_cents_start = dts.first.drawer_amount_cents
    drawer_amount_cents_cumulated = drawer_amount_cents_start
    dts.each do |dt|
      
      # ---
      should = drawer_amount_cents_cumulated
      actual = dt.drawer_amount_cents
      pass = should == actual
      msg = "drawer_amount_cents wrongly cumulated. difference is #{ should - actual }"
      type = :drawerTransactionWronglyCumulated
      tests << {:model=>"DrawerTransaction", :id=>dt.id, :t=>type, :m=>msg, :s=>should, :a=>actual} if pass == false
      
      if pass == false
        # reset cumulated value, otherwise all following dts will be wrong. however, we only want to see the DTs that introduced a difference
        drawer_amount_cents_cumulated = dt.drawer_amount_cents
      end
      
      drawer_amount_cents_cumulated += dt.amount_cents
    end
   
    return tests
  end
  
  def transact(amount_cents, user, cash_register, tag='', notes='', order=nil)
    dt = DrawerTransaction.new
    dt.vendor = cash_register.vendor
    dt.company = self.company
    dt.drawer_amount = self.amount
    dt.drawer = self
    dt.user = user
    dt.amount_cents = amount_cents
    dt.currency = cash_register.vendor.currency
    dt.tag = tag
    dt.notes = notes
    dt.cash_register = cash_register
    if order
      dt.order = order
      dt.complete_order = true
    end
    dt.save!
    
    self.amount_cents += amount_cents
    self.save
    
    return dt
  end
  
end
