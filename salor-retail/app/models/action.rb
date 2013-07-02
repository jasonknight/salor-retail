# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Action < ActiveRecord::Base

  include SalorScope
  include SalorBase

  belongs_to :role
  belongs_to :vendor
  belongs_to :company
  belongs_to :user
  belongs_to :model, :polymorphic => true
  
  def self.when_list
    [:add_to_order, :always, :on_save, :on_import, :on_export]
  end
  
  def self.behavior_list
    [:add, :subtract, :multiply, :divide, :assign, :discount_after_threshold]
  end
  
  def self.afield_list
    [:price, :quantity,:tax_profile_id, :packaging_unit]
  end


  def self.run(item, act)
    return if item.class != OrderItem
    base_item = item.item
      base_item = item.item
  
    base_item.actions.visible.each do |action|
      item = Action.apply_action(action, item, act)
    end

    if base_item.category and base_item.category.actions.visible.any? then
      base_item.category.actions.visible.each do |action|
        item = Action.apply_action(action, item, act)
      end
    end
    return item
  end
  
  def self.apply_action(action, item, act)
    if act == action.whento.to_sym or action.whento.to_sym == :always  then
      eval("item.#{action.afield} += action.value") if action.behavior.to_sym == :add
      eval("item.#{action.afield} -= action.value") if action.behavior.to_sym == :subtract
      eval("item.#{action.afield} *= action.value") if action.behavior.to_sym == :multiply
      eval("item.#{action.afield} /= action.value") if action.behavior.to_sym == :divide
      eval("item.#{action.afield} = action.value") if action.behavior.to_sym == :assign
      
      if action.behavior.to_sym == :discount_after_threshold and act == :add_to_order and action.model.class == Category
        items_in_cat = item.order.order_items.visible.where(:category_id => action.model.id)
        total_quantity = items_in_cat.sum(:quantity)
        items_in_cat.update_all :rebate => 0
        item_price = items_in_cat.minimum(:price)
        num_discountables = (total_quantity / action.value2).floor
        if num_discountables >= 1 then
          item.rebate = (100 * num_discountables * item_price / item.subtotal).round(2)
        end
        item.save
      end
    end
    return item
  end
end
