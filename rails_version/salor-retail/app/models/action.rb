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
  
  validates_presence_of :vendor_id, :company_id, :name, :whento, :behavior

  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
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
      return "Vendor:" + self.model.id.to_s
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
  
  def value=(pricestring)
    val = self.string_to_float(pricestring, :locale => self.vendor.region)
    write_attribute :value, val
  end
  
  
  def self.when_list
    return [
      nil,
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
      nil,
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
      nil,
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

  def location_id
    if self.model.class == Location then
      return self.model.id
    else
      return nil
    end
  end

  def location_id=(id)
    return if id.blank?
    self.model = self.vendor.locations.find_by_id(id)
  end

  def sku
    if self.model and self.model.class == Item
      return self.model.sku
    end
    return ""
  end

  def sku=(s)
    self.model = Item.find_by_sku(s)
  end
  
  def self.run(the_vendor, item, act)
    SalorBase.log_action "Action", "run called for #{ act }", :light_red
    if item.class == OrderItem then
      base_item = item.item
    else
      base_item = item
    end
    
    redraw_all_pos_items = nil
   
    if base_item.class != Vendor and base_item.kind_of? ActiveRecord::Base
      the_vendor.actions.visible.where(:model_type => 'Vendor', :model_id => the_vendor).where(["whento = ? or whento = 'always'",act]).each do |action|
        redraw_all_pos_items = Action.apply_action(action, item, act)
      end
      
      base_item.actions.where(["whento = ? or whento = 'always'",act]).visible.each do |action|
        redraw_all_pos_items = Action.apply_action(action, item, act)
      end

      if base_item.category then
        base_item.category.actions.where(["whento = ? or whento = 'always'",act]).visible.each do |action|
          redraw_all_pos_items = Action.apply_action(action, item, act)
        end
      end
      
      if base_item.location then
        base_item.location.actions.where(["whento = ? or whento = 'always'",act]).visible.each do |action|
          redraw_all_pos_items = Action.apply_action(action, item, act)
        end
      end
      
    else
      the_vendor.actions.visible.where(:model_type => 'Vendor', :model_id => the_vendor.id).where(["whento = ? or whento = 'always'",act]).each do |action|
        redraw_all_pos_items = action.execute_script(item)
      end
    end
    return redraw_all_pos_items
  end
  
  def execute_script(item, act)

    return item if self.js_code.nil?
    the_user = User.find_by_id($USERID)
    if item.kind_of? ActiveRecord::Base and item.class != Vendor then
      the_vendor = item.vendor
    elsif item.class == Vendor
      the_vendor = item
    else
      return item
    end
    if not the_user.company == the_vendor.company then
      return item
    end
    # have to do this to prevent access to the object from inside JS
    # but we want to be able to access it from other parts of the code
    secret = Digest::SHA2.hexdigest(the_user.encrypted_password)[0..8]
    api = JsApi.new(self.name + " Action", act, the_vendor.company, the_vendor, the_user, secret)
    api.set_object(item) # this is object that the script will operate on
    api.set_writeable(secret,false) if item.class == Vendor 
    api.evaluate_script(self.js_code)
    item = api.get_object(secret) # and then we get it back out
    return item
  end
  
  def self.apply_action(action, item, act)

    SalorBase.log_action Action, "Action.apply_action " + action.name + " action_id:#{action.id}"
    
    redraw_all_pos_items = nil
    
    return redraw_all_pos_items if action.whento.nil?
    
    if act == action.whento.to_sym or action.whento.to_sym == :always  then
      
      if action.behavior.to_sym == :execute then
        return action.execute_script(item, act);
      end

      if action.afield == "price_cents" &&
          (action.behavior.to_sym == :add ||
           action.behavior.to_sym == :substract ||
           action.behavior.to_sym == :assign
          )
        the_value = action.value * 100
      else
        the_value = action.value
      end
      
      case action.behavior.to_sym
      when :add
        eval("item.#{action.afield} += the_value")
        item.action_applied = true
        item.save!
        
      when :substract
        eval("item.#{action.afield} -= the_value")
        item.action_applied = true
        item.save!
        
      when :multiply
        eval("item.#{action.afield} *= the_value")
        SalorBase.log_action Action, "multiplying", :blue
        item.action_applied = true
        item.save!
        
      when :divide
        eval("item.#{action.afield} /= the_value")
        item.action_applied = true
        item.save!
        
      when :assign
        eval("item.#{action.afield} = the_value")
        item.action_applied = true
        item.save!
      
      # Welcome to one of the most complicated bits of code in the system.
      # The basic idea:

      # The action.value is a float from 0-1.0 That represents the amount of the
      # price to discount once the threshold action.value2 is met.

      # IF This action applies to a Category or a Location, then we need to get all the
      # order items present in that Category or Location, and Discount the LEAST expensive
      # item.
      when :discount_after_threshold
        SalorBase.log_action Action,"[Discount after threshold]: called"

        if action.model.class == Category or action.model.class == Location then
          SalorBase.log_action Action,"[Discount after threshold]: Is a category discount"
          items_in_cat = item.order.order_items.visible.where(:category_id => action.model.id) if action.model.class == Category
          items_in_cat = item.order.order_items.visible.where(:category_id => action.model.id) if action.model.class == Location
          return if items_in_cat.blank?
          total_quantity = items_in_cat.sum(:quantity)
          SalorBase.log_action Action,"[Discount after threshold]: Total quantity is #{ total_quantity }"
          minimum_price_item = nil
          minimum_price = 9999999
          items_in_cat.each do |i|
            if i.price_cents < minimum_price
              minimum_price_item = i 
              minimum_price = i.price_cents
            end
          end
          SalorBase.log_action Action,"[Discount after threshold]: Minimum price is #{ minimum_price }, minimum price item ID is #{ minimum_price_item.inspect }"
          num_discountables = (total_quantity / (action.value2 + 1)).floor
          SalorBase.log_action Action,"[Discount after threshold]: num_discountables is #{ num_discountables}"
          
          # reset all relevant items
          items_in_cat.each do |oi|
            oi.price_cents = oi.item.price_cents
            oi.coupon_amount_cents = 0
            oi.action_applied = nil
            oi.calculate_totals
          end
          
          if num_discountables >= 1
            SalorBase.log_action Action,"[Discount after threshold]: Applying action"
            # Note: This is misusing the coupon_amount attribute. TODO: Create an 'action_amount_cents' attribute, however this will require quite extensive changes in the calculations in Order and Item models. It works for now.
            
            if num_discountables > minimum_price_item.quantity
              max_discountables = minimum_price_item.quantity
            else
              max_discountables = num_discountables
            end
            
            minimum_price_item.coupon_amount_cents = action.value * max_discountables * minimum_price_item.price_cents
            minimum_price_item.action_applied = true
            minimum_price_item.calculate_totals
          else
            SalorBase.log_action Action,"XXXX[Discount after threshold]: num_discountables is not sufficient"
            minimum_price_item.coupon_amount_cents = 0
            minimum_price_item.action_applied = nil
            minimum_price_item.calculate_totals
          end
          
          redraw_all_pos_items = true
          
        else
          SalorBase.log_action Action,"[Discount after threshold]: Is regular"
          minimum_price = item.price_cents
          num_discountables = (item.quantity / action.value2).floor
          minimum_price_item = item
          minimum_price_item.coupon_amount_cents = action.value * num_discountables * minimum_price_item.price_cents
          minimum_price_item.action_applied = true
          minimum_price_item.calculate_totals
        end
        

      end
    end

    return redraw_all_pos_items
  end
end
