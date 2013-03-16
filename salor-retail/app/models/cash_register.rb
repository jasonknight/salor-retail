# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class CashRegister < ActiveRecord::Base
  # {START}
  include SalorScope
  include SalorBase
  include SalorModel
  has_many :cash_register_dailies
  has_many :vendor_printers
  belongs_to :vendor
  has_many :orders
  has_many :meta
  has_many :drawer_transactions
  def end_of_day_report
    table = {}
    cats_tags = Category.cats_report($User.get_drawer.id)
    @orders = Order.by_vendor.by_user.where(:refunded => false,:drawer_id => $User.get_drawer.id,:paid => true,:created_at => Time.now.beginning_of_day..Time.now)
    paymentmethod_sums = Hash.new
    cashtotal = 0.0
    @orders.each do |o|
      cashtotal += o.get_drawer_add
      o.payment_methods.each do |pm|
        paymentmethod_sums[pm.name] ||= 0 if not pm.internal_type == 'InCash'
        paymentmethod_sums[pm.name] += pm.amount if not pm.internal_type == 'InCash'
        if pm.amount < 0 then
          #cash_total += pm.amount if pm.internal_type != 'InCash'
        end
      end
    end
    paymentmethod_sums[I18n.t("InCash")] = cashtotal
    cats_tags.merge!(paymentmethod_sums)
    return cats_tags
  end
  
  def self.update_all_devicenodes
    return # this is crazy complicated.
    # Update device paths of all Rails-printing CashRegisters AND the currently selected CashRegister, independent of being Rails or client side printing.
    devices_for_select, devices_name_path_lookup =  CashRegister.get_devicenodes
    $Vendor.cash_registers.visible.each do |cr|
      next if cr.salor_printer == true and not cr == $Register
      cr.set_device_paths_from_device_names(devices_name_path_lookup)
      if cr == $Register
        cr.reload
        $Register = cr
      end
    end
  end
  
  def self.get_devicenodes
    nodes_usb1 = Dir['/dev/usb/lp*']
    nodes_usb2 = Dir['/dev/usblp*']
    nodes_serial = Dir['/dev/usb/ttyUSB*']
    nodes_salor = Dir['/dev/salor*']
    nodes_test = Dir['/tmp/salor-test*']
    all_nodes = nodes_usb1 + nodes_usb2 + nodes_serial + nodes_salor + nodes_test
    devices_for_select = []
    all_nodes.each do |n|
      if not n.include? '.txt' then
        devicename = `/sbin/udevadm info -a -p  $(/sbin/udevadm info -q path -n #{n}) | grep ieee1284_id`
      else
        devicename = n
      end
      # Why not just be direct about it? You have the name, and you have the path, you can choose what you display in the selected
      # Why would we even need a lookup table?
      if not devicename.include? '.txt' then
        match = /^.*L:(.*?)\;.*/.match(devicename)
        devicename = match ? match[1] : '?' + n
      end
      devices_for_select << [devicename,n]
    end
   return devices_for_select
  end
  
  def set_device_paths_from_device_names(devices_name_path_lookup)
    return
    self.cash_drawer_name = self.thermal_printer_name
    self.cash_drawer_path = devices_name_path_lookup[self.cash_drawer_name] unless self.cash_drawer_name.nil?
    self.thermal_printer = devices_name_path_lookup[self.thermal_printer_name] unless self.thermal_printer_name.nil?
    self.sticker_printer = devices_name_path_lookup[self.sticker_printer_name] unless self.sticker_printer_name.nil?
    self.scale = devices_name_path_lookup[self.scale_name] unless self.scale_name.nil?
    self.save
  end
end
