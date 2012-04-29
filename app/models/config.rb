# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class SalorConfiguration < ActiveRecord::Base
  include SalorScope
  include SalorModel
  belongs_to :vendor
  def make_valid
    [:dollar_per_lp,:lp_per_dollar].each do |f|
      if self.send(f) == nil then
        self.update_attribute(f,0)
      end
    end
  end
end
