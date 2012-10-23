# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Session < ActiveRecord::Base
  def self.sweep(time = 24.hours)
    time = time.split.inject { |count, unit|
      count.to_i.send(unit)
    } if time.is_a?(String)
 
    delete_all "updated_at < '#{time.ago.to_s(:db)}'"
  end
end
