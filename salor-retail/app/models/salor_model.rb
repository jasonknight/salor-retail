# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorModel
  def self.included(mod)
    mod.class_eval do
      has_many :salor_errors, :as => :owner, :class_name => "Error"
      has_many :unseen_salor_errors, :as => :owner, :class_name => "Error", :conditions => "seen IS FALSE"
      has_many :salor_errors_applied, :as => :applies_to, :class_name => "Error"
      attr_accessor :node_skip
      def _get_id_field_from(sku_field_name)
        return sku_field_name.gsub("sku","id").to_sym
      end
      # This code is here to help nodes communicate about models in each others systems.
      # because ids wouldn't be unique
      def tax_profile_sku=(sku)
        sym = _get_id_field_from("tax_profile_sku=")
        model = TaxProfile.where(:sku => sku).first
        if model then
          self.update_attribute :tax_profile_id,model.id
        end
      end
#
      def has_relations?
        return true if self.class == Item and self.order_items.any?
        return true if self.class == Order and self.order_items.visible.any?
        return true if self.class == Shipment and self.shipment_items.any?
        return true if self.class == Vendor
        if self.class == Discount then
          if self.order_items or self.orders then
            return true
          end
        end
        return false
      end
#
      def kill
        if self.has_relations? and self.respond_to? :hidden and self.hidden.class == Fixnum then
          self.update_attribute(:hidden,1)
        else
          if self.respond_to? :hidden and self.hidden.class == Fixnum then
            self.update_attribute :hidden, 1
          elsif self.respond_to? :hidden then
            self.update_attribute :hidden, true
          else
            self.destroy
          end
        end
      end
#
    end # mod.class_eval
  end # self.included
end
