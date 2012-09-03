# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class GlobalErrors
  @@errors = []
  @@fatals = []
  def self.<<(error)
    @@errors << error #expects it to be an array
    e = Error.new(:msg => error[0])
    e.save
  end
  def self.append(error,obj=nil,opts={})
    @@errors << [error,I18n.t(error,opts) + " (#{error.camelize})",obj]
    e = Error.new(:msg => I18n.t(error,opts), :applies_to => obj)
    e.save
  end
  def self.append_fatal(error,obj=nil,opts={})
    @@fatals << [error,I18n.t(error,opts),obj]
    e = Error.new(:msg => I18n.t(error,opts), :applies_to => obj)
    e.save
  end
  def self.get_fatals
    return @@fatals
  end
  def self.get_errors
    return @@errors
  end
  def self.any?
    return @@errors.any?
  end
  def self.any_fatal?
    return @@fatals.any?
  end
  def self.has_error(str)
    @@errors.each do |e|
      return true if e[0] == str
    end
    @@fatals.each do |f|
      return true if f[0] == str
    end
    return false
  end
  def self.all
    @@fatals + @@errors
  end
  def self.flush
    @@errors = []
    @@fatals = []
  end
end
