# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class CashRegister < ActiveRecord::Base
  include SalorScope
  include SalorBase

  has_many :current_register_dailies
  has_many :vendor_printers
  has_many :drawer_transactions
  
  belongs_to :vendor
  belongs_to :company
  
  has_many :orders
  
  validates_presence_of :name
  validates_presence_of :vendor_id, :company_id
  
  before_save :sanitize_path
  
  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end
  
  def open_cash_drawer
    return if self.company.mode != 'local'
    vp = Escper::VendorPrinter.new({})
    vp.id = 0
    vp.name = self.name
    vp.path = self.thermal_printer
    vp.copies = 1
    vp.codepage = 0
    vp.baudrate = 9600
    
    print_engine = Escper::Printer.new(self.company.mode, vp, File.join(SalorRetail::Application::SR_DEBIAN_SITEID, self.vendor.hash_id))
    print_engine.open
    text = self.open_cash_drawer_code
    print_engine.print(0, text)
    print_engine.close
  end
  
  def open_cash_drawer_code
    "\x1B\x70\x00\x55\x55"
  end
  
  def get_devicenodes
    if self.company.mode != 'local'
      log_action "This method is allowed to run only on local installations"
      return []
    end
    nodes_usb1 = Dir['/dev/usb/lp*']
    nodes_serial = Dir['/dev/ttyUSB*']
    nodes_test = Dir['/tmp/salor-test*']
    all_nodes = nodes_usb1 + nodes_serial +  nodes_test
    devices_for_select = []
    all_nodes.each do |n|
      if not n.include? '.txt' then
        devicename = `/sbin/udevadm info -a -p  $(/sbin/udevadm info -q path -n #{n}) | grep ieee1284_id`
      else
        devicename = n
      end
      # Why not just be direct about it? You have the name, and you have the path, you can choose what you display in the select
      # Why would we even need a lookup table?
      # Answer: Because device paths can change after reboot, which would break printing for non-techie users, and we only take the ieee1284_id name for granted (stored on the microchips of the devices) and update the path accordingly when they log in or visit the POS page (see before_filters when this is executed). The alternative is to write custom udev rules that give device nodes a specific name based on the USB port location (e.g. /dev/usb-port-top-left), instead of generic ones (e.g. /dev/usb/lp0), but that has to be done manually and specifically for each mainboard revision, which is time consuming and painful.
      if not devicename.include? '.txt' then
        match = /^.*L:(.*?)\;.*/.match(devicename)
        devicename = match ? match[1] : '' + n
      end
      devices_for_select << [devicename,n]
    end
   return devices_for_select
  end
  
  def set_device_paths_from_device_names
    if self.company.mode != 'local'
      log_action "This method is allowed to run only on local installations"
      return
    end
    devices_for_select = self.get_devicenodes
    devices_for_select.each do |dev|
      [:cash_drawer,:thermal_printer,:sticker_printer,:scale,:pole_display].each do |a|
        # on each pass it will look like this: self.send("thermal_printer_name","TM-T20")
        # This holds true for pole_display, scale, etc...
        if self.send("#{a}_name") == dev.first then
          # on each pass it would look like this: self.send("thermal_printer=","/dev/usb/lp0") etc
           next if a == :cash_drawer # We have to intercept this one, cause it doesn't fit the pattern
          if a == :thermal_printer then
            self.send("#{a}=",dev.last)
            self.cash_drawer_path = dev.last
          else
            self.send("#{a}=",dev.last)
          end 
        end
      end
    end
    self.save
  end
  
  def sanitize_path
    if self.company.mode != 'local'
      self.thermal_printer = self.thermal_printer.to_s.gsub(/[\/'"\&\^\$\#\!;\*]/,'_').gsub(/[^\w\/\.\-@]/,'')
      self.cash_drawer_path = self.cash_drawer_path.to_s.gsub(/[\/'"\&\^\$\#\!;\*]/,'_').gsub(/[^\w\/\.\-@]/,'')
      self.sticker_printer = self.sticker_printer.to_s.gsub(/[\/'"\&\^\$\#\!;\*]/,'_').gsub(/[^\w\/\.\-@]/,'')
      self.a4_printer = self.a4_printer.to_s.gsub(/[\/'"\&\^\$\#\!;\*]/,'_').gsub(/[^\w\/\.\-@]/,'')
      self.pole_display = self.pole_display.to_s.gsub(/[\/'"\&\^\$\#\!;\*]/,'_').gsub(/[^\w\/\.\-@]/,'')
    end
  end
  
  def salor_printer
    if self.company.mode == 'local'
      return read_attribute :salor_printer
    else
      # remote installations always have to use the salor-bin printing method. In the view, the check box will be hidden.
      return true
    end
  end
  
end
