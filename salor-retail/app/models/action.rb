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

  def category_id
    if self.model.class == Category then
      return self.model.id
    else
      return nil
    end
  end

  def category_id=(id)
    self.model = self.vendor.categories.find_by_id(id)
  end

  def sku
    if self.model and self.model.class == Item
      return self.model.sku
    end
    return self.model.class.to_s
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
    SalorBase.log_action Action,"Beginning to apply actions"
    if act == action.whento.to_sym or action.whento.to_sym == :always  then
      eval("item.#{action.afield} += action.value") if action.behavior.to_sym == :add
      eval("item.#{action.afield} -= action.value") if action.behavior.to_sym == :subtract
      eval("item.#{action.afield} *= action.value") if action.behavior.to_sym == :multiply
      eval("item.#{action.afield} /= action.value") if action.behavior.to_sym == :divide
      eval("item.#{action.afield} = action.value") if action.behavior.to_sym == :assign
      
      if action.behavior.to_sym == :discount_after_threshold then
        SalorBase.log_action Action,"Discount after threshold"
        item.action_applied = true
        if act == :add_to_order and action.model.class == Category
          SalorBase.log_action Action,"Is a category discount"
          items_in_cat = item.order.order_items.visible.where(:category_id => action.model.id)
          total_quantity = items_in_cat.sum(:quantity)
          items_in_cat.update_all :rebate => 0
          item_price = items_in_cat.minimum(:price_cents)
          num_discountables = (total_quantity / action.value2).floor
        elsif action.behavior.to_sym == :discount_after_threshold and act == :add_to_order
          SalorBase.log_action Action,"Is regular discount_after_threshold"
          item_price = item.price
          num_discountables = (item.quantity / action.value2).floor
        end
        item.rebate = 0 # Important
        if num_discountables >= 1 then
          SalorBase.log_action Action,"discount #{num_discountables} and item_price is #{item_price}"
          total_2_discount = Money.new(item_price * num_discountables, item.price_currency)
          
          percentage = total_2_discount / (item.price * item.quantity)
          item.rebate = (percentage * 100).to_i
          SalorBase.log_action Action,"rebate is #{item.rebate}"
          item.save
        else
          SalorBase.log_action Action,"num_discountables is not sufficient"
        end
        item.save # Important
      end
    end
    return item
  end
end
