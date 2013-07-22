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
  
end
