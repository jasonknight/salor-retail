# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

begin
  class CuteCredit < ActiveRecord::Base
      establish_connection "cute_credit"
      set_table_name :messages
  end
rescue
  class CuteCredit
    def self.method_missing(m,*args, &block)
      
    end
  end
end
