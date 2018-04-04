# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class AppConfig
  
  @@config = SalorRetail::Application::CONFIGURATION
  
  def self.config
    return @@config
  end
  
  def self.method_missing(sym, *args, &block)
   
    if @@config[sym.to_s] then
      if @@config[sym.to_s].class == Hash then
        return ValueProxy.new(@@config[sym.to_s])
      else
        return @@config[sym.to_s]
      end
    end
  end
  
  def self.respond_to?(sym,include_private=false)
    true
  end
end