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
      vendor_printer = VendorPrinter.new :path => $Register.thermal_printer
      text = self.escpos
      printr = Printr::Printr.new('local', vendor_printer)
      printr.open
      printr.print 0, Printr::Printr.sanitize(text)
      printr.close
      Receipt.create(:employee_id => @User.id, :cash_register_id => $Register.id, :content => text)
    end
  end
  
  def escpos
    init = 
    "\e@"     +  # Initialize Printer
    "\ea\x01" +  # align center
    "\e!\x38" +
    DrawerTransaction.model_name.human + ' ' +
    self.id.to_s +
    "\n\n" +
    "\e!\x01" +
    I18n.l(self.created_at, :format => :long) +
    "\n\n" +
    "\e!\x38" +
    $User.username +
    "\n\n" +
    self.tag +
    "\n\n" +
    self.notes +
    "\n\n" +
    "\e!\x38" +
    SalorBase.to_currency(self.amount) +
    "\n\n" +
    I18n.t(self.drop ? 'printr.word.drop' : 'printr.word.payout') +
    "\n\n\n\n\n\n\n" +
    "\x1D\x56\x00" +  # cut
    "\x1B\x70\x00\x30\x01" # open cash drawer
    
    #GlobalData.vendor.receipt_logo_footer 
  end
  # {END}
end
