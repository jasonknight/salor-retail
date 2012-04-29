# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class SalorSession
  @@data = {}
  def self.cast(v)
    if v.class == Fixnum then
      return :to_i
    elsif v.class == String then
      return :to_s
    elsif v.class == Float
      return :to_f
    end
  end
  def self.[]=(k,v)
    @@data ||= {}
    @@data[k] = v
  end
  def self.[](k)
    @@data ||= {}
    return @@data[k]
  end
  def self.dump
    @@data ||= {}
    File.open(File.join(Rails.root.to_s,"tmp", $IP),"w+") do |f|
      f.write Marshal.dump(@@data)
    end
  end
  def self.load
    @@data ||= {}
    begin
    File.open(File.join(Rails.root.to_s,"tmp", $IP),"r") do |f|
      @@data = Marshal.load(f.read)
    end
    rescue
      #seems we didn't have a file...oh well
      puts $!.inspect
    end
  end
end
