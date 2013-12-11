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
  
  validates_presence_of :vendor_id, :company_id, :name, :model_type, :model_id

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
    return ""
  end

  def sku=(s)
    self.model = Item.find_by_sku(s)
  end
  
  def self.run(the_vendor, item, act)
    SalorBase.log_action "Action", "run called", :light_red
    if item.class == OrderItem then
      base_item = item.item
    else
      base_item = item
    end
    
    if base_item.class != Vendor and base_item.kind_of? ActiveRecord::Base then
      the_vendor.actions.visible.where(:model_type => 'Vendor', :model_id => the_vendor).where(["whento = ? or whento = 'always'",act]).each do |action|
        item = Action.apply_action(action, item, act)
      end
      base_item.actions.where(["whento = ? or whento = 'always'",act]).visible.each do |action|
        item = Action.apply_action(action, item, act)
      end

      if base_item.category then
        base_item.category.actions.where(["whento = ? or whento = 'always'",act]).visible.each do |action|
          item = Action.apply_action(action, item, act)
        end
      end
    else
      the_vendor.actions.visible.where(:model_type => 'Vendor', :model_id => the_vendor.id).where(["whento = ? or whento = 'always'",act]).each do |action|
        item = action.execute_script(item)
      end
    end
    return item
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
    api = JsApi.new(self.name, act, the_vendor.company, the_vendor, the_user, secret)
    api.set_object(item) # this is object that the script will operate on
    api.set_writeable(secret,false) if item.class == Vendor 
    api.evaluate_script(self.js_code)
    item = api.get_object(secret) # and then we get it back out
    return item
  end
  
  def self.apply_action(action, item, act)
    SalorBase.log_action Action, "Action.apply_action " + action.name + " action_id:#{action.id}"
    return item if action.whento.nil?
    item.action_applied = true
    if act == action.whento.to_sym or action.whento.to_sym == :always  then
      if action.behavior.to_sym == :execute then
        return action.execute_script(item, act);
      end
      #SalorBase.log_action Action, "item.#{action.afield} += action.value" + " #{item.send(action.afield).inspect}"
      if ([:price, :base_price].include? action.afield.to_sym) then
        the_value = Money.new(action.value * 100, item.currency)
      else
        the_value = action.value
      end

      #SalorBase.log_action Action, "item.#{action.afield} += action.value" + " #{item.send(action.afield).inspect} + #{the_value.inspect}"
      eval("item.#{action.afield} += the_value") if action.behavior.to_sym == :add
      eval("item.#{action.afield} -= the_value") if action.behavior.to_sym == :subtract
      eval("item.#{action.afield} *= the_value") if action.behavior.to_sym == :multiply
      eval("item.#{action.afield} /= the_value") if action.behavior.to_sym == :divide
      eval("item.#{action.afield} = the_value") if action.behavior.to_sym == :assign


      
      if action.behavior.to_sym == :discount_after_threshold then
        SalorBase.log_action Action,"Discount after threshold"
        if act == :add_to_order and action.model.class == Category
          SalorBase.log_action Action,"Is a category discount"
          items_in_cat = item.order.order_items.visible.where(:category_id => action.model.id)
          total_quantity = items_in_cat.sum(:quantity)
          items_in_cat.update_all :rebate => 0
          item_price = items_in_cat.minimum(:price_cents)
          num_discountables = (total_quantity / action.value2).floor
        elsif action.behavior.to_sym == :discount_after_threshold and act == :add_to_order
          SalorBase.log_action Action,"Is regular discount_after_threshold"
          item_price = item.price_cents
          num_discountables = (item.quantity / action.value2).floor
        end
        item.rebate = 0 # Important
        if num_discountables >= 1 then
          SalorBase.log_action Action,"discount #{num_discountables} and item_price is #{item_price}"
          total_2_discount = item_price * num_discountables
          SalorBase.log_action Action, total_2_discount.inspect
          percentage = total_2_discount / (item.price_cents * item.quantity)
          SalorBase.log_action Action, "total_2_discount is #{total_2_discount} and percentage is #{percentage}"
          item.rebate = (percentage * 100).to_i
          SalorBase.log_action Action,"rebate is #{item.rebate}"

          item.save
        else
          SalorBase.log_action Action,"num_discountables is not sufficient"
        end
      end
    end
    item.save!
    return item
  end
end
