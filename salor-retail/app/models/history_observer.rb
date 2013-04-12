# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class HistoryObserver < ActiveRecord::Observer
  include SalorBase
  observe :order_item, :item, :order, :employee, :customer, :loyalty_card
  def after_update(object)
    if object.class == Order then
      #order rules go here
      object.changes.keys.each do |k|
        if [:hidden, :total, :paid,:rebate].include? k.to_sym then
          History.record('order_edit_' + k,object,2)
          return
        end
      end
    elsif object.class == OrderItem then
      object.changes.keys.each do |k|
        if [:price, :hidden, :total, :rebate,:action_applied, :discount_amount].include? k.to_sym then
          History.record('order_item_edit_' + k,object,3)
          return
        end
      end
    elsif object.class == LoyaltyCard then
      # i.e. we should only track point changes that are very large
      # FIXME this should be relative to the stores setting in some way
      if object.changes['points'] and (object.changes['points'][1].to_i - object.changes['points'][0].to_i) > 200 then
        History.record("loyalty_card_points",object,4)
        return
      end
    else
      object.changes.keys.each do |k|
        if [:base_price, :price, :hidden, :value, :sku, :name, :amount].include? k.to_sym then
          History.record("#{object.class.to_s.downcase}_edit_#{k}",object,5)
          return
        end
      end
    end 
  end
  def before_destroy(object)
    sen = 2
    if [:order,:order_item,:employee].include? "#{object.class}".to_sym then
      sen = 1
    end
    History.record("destroy_#{object.class.to_s}",object,sen)
  end
end

