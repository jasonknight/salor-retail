# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class GlobalData
  # This is a Locator/Broker class for global data that
  # Needs to be accessible everywhere!
  @@attrs = nil
  def self.cash_drawer
    p = 'NotSet'
    if self.cash_register and self.cash_register.cash_drawer_path then
      p = '' if self.cash_register.cash_drawer_path.to_s == '0'
      p =  self.cash_register.cash_drawer_path
    else
      p = self.conf.cash_drawer
    end
    return p
  end
  def self.refresh
    @@attrs = nil
  end
  def self.reload(sym)
    sym = sym.to_s
    @@attrs[sym].reload if @@attrs[sym]
  end
  def refresh
    @@attrs = nil
  end
  def self.method_missing(sym, *args, &block)
    @@attrs ||= {}
    osym = sym
    sym = sym.to_s
    if sym.include? "=" then
      @@attrs[sym.gsub('=','')] = args.first
    else
      if @@attrs[sym].class == Hash then
        return ValueProxy.new(@@attrs[sym])
      else
        if @@attrs[sym] then
          return @@attrs[sym]
        else
          #k it wasn't found, so let's find it and set it
          if osym == :vendors then
            self.vendors = self.salor_user.get_vendors(nil)
            return self.vendors
          elsif osym == :categories then
            self.categories = self.salor_user.get_all_categories
            return self.categories
          elsif osym == :conf then
            if self.params.vendor_id then
              self.conf = SalorConfiguration.find_by_vendor_id(self.params.vendor_id)
              return self.conf
            end
            return nil
          elsif osym == :locations then
            self.locations = self.salor_user.get_locations
            return self.locations
          elsif osym == :item_types then
            self.item_types = ItemType.all
            return self.item_types
          elsif osym == :tax_profiles then
            self.tax_profiles = self.salor_user.get_tax_profiles
            return self.tax_profiles
          end
        end #end if @@attrs[sym] then
      end
    end
  end
end
