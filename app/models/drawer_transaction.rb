# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class DrawerTransaction < ActiveRecord::Base
  # {START}
  include SalorBase
  include SalorScope
  include SalorModel
  belongs_to :drawer
  validate :validify
  belongs_to :cash_register
  belongs_to :owner, :polymorphic => true
  def trans_type=(x)
    if x == 'drop' then
      self.drop = true
    else
      self.payout = true
    end
  end
  
  def validify
    self.vendor_id = $Vendor.id
    if self.amount.to_f <= 0 then
      self.amount *= -1.0
    end
    if not self.drop and not self.payout then
      GlobalErrors.append_fatal("system.errors.must_specify_drop_or_payout")
      errors.add(:drop,I18n.t("system.errors.must_specify_drop_or_payout"))
    end
    if self.cash_register_id.nil? then
      self.set_model_owner
    end
  end
  def amount=(p)
    write_attribute(:amount,self.string_to_float(p))
  end

  def print
    if $Register.id
      @dt = self
      text = Printr.new.sane_template("drawer_transaction_receipt",binding)
      Printr.new.direct_write($Register.thermal_printer,text)
    end
  end
  # {END}
end
