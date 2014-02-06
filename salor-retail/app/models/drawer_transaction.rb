# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class DrawerTransaction < ActiveRecord::Base
  include SalorBase
  include SalorScope

  belongs_to :vendor
  belongs_to :company
  belongs_to :drawer
  belongs_to :user
  belongs_to :order
  belongs_to :cash_register

  monetize :amount_cents, :allow_nil => true
  monetize :drawer_amount_cents, :allow_nil => true
  
  validates_presence_of :vendor_id
  validates_presence_of :company_id
  validates_presence_of :drawer_id
  validates_presence_of :user_id

  before_create :set_nr

  def set_nr
    i = self.vendor.largest_drawer_transaction_number + 1
    self.nr = i
    self.vendor.update_attribute :largest_drawer_transaction_number, i
  end

  def print
    return if self.company.mode != 'local'
    vp = Escper::VendorPrinter.new({})
    vp.id = 0
    vp.name = self.cash_register.name
    vp.path = self.cash_register.thermal_printer
    vp.copies = 1
    vp.codepage = 0
    vp.baudrate = 9600
    
    text = self.escpos
    print_engine = Escper::Printer.new(self.company.mode, vp, File.join(SalorRetail::Application::SR_DEBIAN_SITEID, self.vendor.hash_id))
    print_engine.open
    print_engine.print(0, text)
    print_engine.close
    
    r = Receipt.new
    r.vendor = self.vendor
    r.company = self.company
    r.user = self.user
    r.drawer = self.drawer
    r.cash_register = self.cash_register
    r.content = text
    r.save!
    
    return text
  end
  
  def escpos
    init = 
    "\e@"     +  # Initialize Printer
    "\x1B\x70\x00\x30\x01" + # open cash drawer early
    "\ea\x01" +  # align center
    "\e!\x38" +
    DrawerTransaction.model_name.human +
    "\n" +
    self.id.to_s +
    "\n\n" +
    "\e!\x01" +
    I18n.l(self.created_at, :format => :long) +
    "\n\n" +
    "\e!\x38" +
    self.user.username +
    "\n\n" +
    self.tag.to_s +
    "\n\n" +
    self.notes.to_s +
    "\n\n" +
    "\e!\x38" +
    self.amount.to_s +
    "\n\n" +
    I18n.t(self.amount_cents > 0 ? 'printr.word.drop' : 'printr.word.payout') +
    "\n\n\n\n\n\n\n" +
    "\x1D\x56\x00" # cut
  end
  
  def self.check_range(from_to)
    messages = []
    dts = DrawerTransaction.where(:created_at => from..to)
    1.upto(dts.size-1).each do |i|
        if dts[i-1].payout
            factor = -1
        else
            factor = 1
        end
        
        if dts[i].drawer_amount.round(2) == (dts[i-1].drawer_amount + dts[i-1].amount * factor).round(2)
            messages << ""
        else
            messages << "#{dts[i].id} not ok: #{dts[i].drawer_amount.round(2)} #{(dts[i-1].drawer_amount + dts[i-1].amount * factor).round(2)}"
        end
    end
    log_action messages.inspect
  end
end
