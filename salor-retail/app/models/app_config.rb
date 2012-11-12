# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class AppConfig
  def self.config
    return @@config
  end
  
  # Configuration loading now takes place in application.rb. This works for developmet and multi-instance installs.
  @@config = SalorRetail::Application::CONFIGURATION
  
#   if ::Rails.env == 'development' then
#      #YAML::load_file("#{::Rails.root.to_s}/config/config.yml")
#   else
#     # This lets us have multiple salors on the same machine.
#     if File.exists?("#{::Rails.root.to_s}/config/salor.yml") then
#       @@config = SalorRetail::Application::CONFIGURATION #YAML::load_file("#{::Rails.root.to_s}/config/salor.yml")
#     else
#       # this is mainly for the standalone install, keeps salor.yml
#       # from being overwritten on update.
#       if File.exists?("/etc/salor.yml") then
#         @@config = SalorRetail::Application::CONFIGURATION #YAML::load_file("/etc/salor.yml")
#       else
#         @@config = SalorRetail::Application::CONFIGURATION #YAML::load_file("#{Rails.root.to_s}/config/config.yml")
#       end
#     end
#   end
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
  def self.logo_check
    # puts "## IN CHECK LOGO"
    if self.logo and File.exists? self.logo then
      # puts "## LOGO IS SET"
      if not File.exists? ::Rails.root.to_s + '/public/images/logo-300.png' then
        # puts "## CREATING LINK"
        FileUtils.link(self.logo + '-300.png',::Rails.root.to_s + '/public/images/logo-300.png')
      end
      return true
    else
      # puts "## NO LOGO IS SET"
    end
    return false
  end
  
end
