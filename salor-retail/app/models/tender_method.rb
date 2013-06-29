# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class TenderMethod < ActiveRecord::Base
  include SalorScope
  include SalorBase

  validate :validify
  
  def validify
    a = SalorBase.alphabet
    aspace = a + ' '
    self.name.each_byte do |b|
      if not aspace.include? b.chr then
        self.errors.add(:name, I18n.t("system.errors.limited_alphabet"))
        break
      end
    end
    self.internal_type.each_byte do |b|
      if not a.include? b.chr then
        self.errors.add(:internal_type, I18n.t("system.errors.limited_alphabet"))
        break
      end
    end
  end
end
