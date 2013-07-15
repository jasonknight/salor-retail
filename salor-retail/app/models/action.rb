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

  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib)
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end

  def vendor_model
    if self.model.class == Vendor then
      return "Vendor:" + self.model.id
    else
      return ""
    end
  end
  def vendor_model=(v)
    if v.include? "Vendor:" then
      t,id = v.split(":")
      self.model_type = t
      self.model_id = id
    end
  end
  def self.when_list
    return [
      :add_to_order, 
      :change_quantity, 
      :change_price, 
      :always, 
      :on_save, 
      :on_import, 
      :on_export,
      :on_sku_not_found
    ]
  end

  def self.behavior_list
    return [
      :add, 
      :subtract, 
      :multiply, 
      :divide, 
      :assign, 
      :discount_after_threshold,
      :execute
    ]
  end
  
  def self.afield_list
    return [
      :price_cents, 
      :quantity, 
      :tax_profile_id, 
      :packaging_unit,
      :attributes
    ]
  end

  def category_id
    if self.model.class == Category then
      return self.model.id
    else
      return nil
    end
  end

  def category_id=(id)
    return if id.blank?
    self.model = self.vendor.categories.find_by_id(id)
  end

  def sku
    if self.model and self.model.class == Item
      return self.model.sku
    end
    return self.model.class.to_s
  end
  
  def self.run(item, act)
    if item.class == OrderItem then
      base_item = item.item
    else
      base_item = item
    end
 
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
    SalorBase.log_action Action, "Action.apply_action"
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
          total_2_discount = Money.new(item_price * num_discountables, item.currency)
          
          percentage = total_2_discount.to_f / (item.price * item.quantity).to_f
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
