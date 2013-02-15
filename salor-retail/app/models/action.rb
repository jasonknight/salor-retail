# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
# {VOCABULARY} actions_done roles_completed owner_info on_import_new on_import_old
# {VOCABULARY} added multiplied subtracted deferred code_completed action_report
class Action < ActiveRecord::Base
  # {START}
  include SalorScope
  include SalorBase
  include SalorModel
  belongs_to :role
  belongs_to :vendor
  belongs_to :owner, :polymorphic => true
  def value=(v)
    v = v.gsub(',','.') if v.class == String
    write_attribute(:value,v)
  end
  def self.when_list
    [:add_to_order,:always,:on_save,:on_import,:on_export]
  end
  def code=(text)
    if code.match(/User|Employee|Vendor|Order|OrderItem|DrawerTransaction/) then
      self.errors[:base] << I18n.t("system.errors.cannot_use_in_code")
    end
    write_attribute(:code,text)
  end
  def self.behavior_list
    [:add,:subtract,:multiply, :divide, :assign,:discount_after_threshold]
  end
  def self.afield_list
    [:base_price, :quantity,:tax_profile_id, :packaging_unit]
  end
  def sku=(s)
    if not s.blank? then
      item = Item.find_by_sku(s)
      if item then
        self.owner_id = item.id
        self.owner_type = 'Item'
      else
        self.errors[:base] << I18n.t("system.errors.no_such_item")
      end
    end
  end
  def category_id=(id)
    c = Category.find_by_id(id)
    if c then
      self.owner_id = c.id
      self.owner_type = "Category"
    end
  end
  def sku
    owner = self.owner
    if owner and owner.respond_to? :sku then
      return owner.sku
    else
      return ''
    end
  end
  def self.apply_action(action,item,act)
    # puts "Considering action: #{action.behavior} #{action.whento}"
    if act == action.whento.to_sym or action.whento.to_sym == :always  then
      # puts "Running action: #{action.behavior} #{action.whento}"
      if action.value > 0 then
        begin
          eval("item.#{action.afield} += action.value") if action.behavior.to_sym == :add and not item.action_applied
          eval("item.#{action.afield} -= action.value") if action.behavior.to_sym == :subtract and not item.action_applied
          eval("item.#{action.afield} *= action.value") if action.behavior.to_sym == :multiply  and not item.action_applied
          eval("item.#{action.afield} /= action.value") if action.behavior.to_sym == :divide and not item.action_applied
          eval("item.#{action.afield} = action.value") if action.behavior.to_sym == :assign and not item.action_applied
          if action.behavior.to_sym == :discount_after_threshold and act == :add_to_order and item.class == OrderItem then
#                 debugger
            if (item.quantity / action.value2).floor >= 1 then
              num_of_discountables = (item.quantity / action.value2).floor
              total_2_discount = num_of_discountables * item.price
              item.rebate = 0
              percentage = total_2_discount / item.calculate_total
              item.rebate = percentage * 100
            else
              item.rebate = 0
            end
            #puts "### item.#{action.afield} -= (item.item.base_price * action.value) * (item.#{action.field2} / action.value2).floor.to_i"
            # eval("item.#{action.afield} =  ((item.item.base_price * item.quantity) - ((item.item.base_price * action.value) * (item.#{action.field2} / action.value2).floor))")
            item.save
          end
          if item.class == OrderItem then
            item.update_attribute :action_applied, true
          end
        rescue
          # puts "Error: #{$!}"
          GlobalErrors.append("system.errors.action_error",action,{:error => $!})
        end
      else
        # puts "ActionValue is #{action.value}"
      end
      if not action.code.blank? then
        begin
          # puts "evaluating code"
          #eval(action.code)
        rescue
          # puts "There was an error #{$!}"
          GlobalErrors.append("system.errors.action_code_error",action,{:error => $!})
        end
      end
    end
    return item
  end
  def self.run(item,act)
    if item.class == OrderItem then
      base_item = item.item
    else
      base_item = item
    end
      base_item.actions.each do |action|
        item = Action.apply_action(action,item,act)
      end
      # puts "At the end of actions, #{item.price}"
      if base_item.category then
        base_item.category.actions.each do |action|
          #raise "Applying Action"
          item = Action.apply_action(action,item,act)
        end
      end
    return item
  end
  def self.simulate(item,action)
     if action.value > 0 then
        begin
          item[action.afield.to_sym] += action.value if action.behavior.to_sym == :add 
          item[action.afield.to_sym] -= action.value if action.behavior.to_sym == :subtract
          item[action.afield.to_sym] *= action.value if action.behavior.to_sym == :multiply
          item[action.afield.to_sym] /= action.value if action.behavior.to_sym == :divide
          item[action.afield.to_sym] = action.value if action.behavior.to_sym == :assign
        rescue
          GlobalErrors.append("system.errors.action_error",action,{:error => $!})
        end
      end
      return item
  end
  # {END}
end
