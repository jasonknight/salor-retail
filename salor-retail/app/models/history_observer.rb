# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class HistoryObserver < ActiveRecord::Observer
  include SalorBase
  observe :order_item, :item, :order
  
  def after_update(object)
    if object.class == Order then
      #order rules go here
      object.changes.keys.each do |k|
        if [:hidden, :total, :paid, :rebate, :tax_profile_id, :is_proforma, :is_buyback].include? k.to_sym then
          History.record('order_edit_' + k, object, 2)
          return
        end
      end
      
    elsif object.class == OrderItem then
      object.changes.keys.each do |k|
        if [:price, :hidden, :total, :rebate, :tax, :tax_profile_id, :quantity, :sku].include? k.to_sym then
          History.record('order_item_edit_' + k, object, 3)
          return
        end
      end
      
    elsif object.class == Item then
      object.changes.keys.each do |k|
        if [:price, :hidden, :sku, :name, :gift_card_amount, :tax_profile_id, :default_buyback].include? k.to_sym then
          History.record("#{object.class.to_s.downcase}_edit_#{k}", object, 5)
          return
        end
      end
    end 
  end
end

