# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class CashRegisterDaily < ActiveRecord::Base
	include SalorScope
	include SalorBase
  belongs_to :cash_register
  belongs_to :employee
  belongs_to :user
  has_many :orders
  def start_amount=(p)
    # puts "##CRD start_amount called"
    if p.class == String then
      p.gsub!(I18n.t("number.currency.format.unit"),'') if p.include? I18n.t("number.currency.format.unit")
      p.gsub!(",",".") if I18n.t("number.currency.format.separator") == ","
      p = p.to_f
      p = p.to_f
    end
    write_attribute(:start_amount,p)
    if self.end_amount == 0 then
      write_attribute(:end_amount,p)
    end
  end
  end
