# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
require 'RMagick'
class Barcode
  def create(code,type='39')
    return get_barcode(code) if File.exists?(eps_path(code)) and File.exists?(png_path(code))
    return make_barcode(code,type)
  end
  def make_barcode(string,type)
    begin
      system("barcode -c -b #{string} -o #{eps_path(string)} -e #{type} -E")
      bc = Magick::ImageList.new(eps_path(string))
      bc.write(png_path(string))
      return get_barcode(string)
    rescue
      return ''
    end
  end
  def get_barcode(string)
    "barcodes/#{string}.png"
  end
  def eps_path(string)
      "#{::Rails.root.to_s}/public/images/barcodes/#{string}.eps"
  end
  def png_path(string)
    "#{::Rails.root.to_s}/public/images/barcodes/#{string}.png"
  end
  def page(&block)
    @_page ||= BarcodePage.new
    yield @_page
  end
  def get_page
    return @_page
  end
  def page_test
    page do |p|
      p.barcodes = [123,456,789,10112,13,14,156,167,189,686,808098,900]
      p.table = {:cols => 2, :rows => 8,:top => 1,:left => 1.5, :right => 1.5, :bottom => 2}
      p.page_width = 210
      p.page_height = 297
      p.filename = "page_test.ps"
      p.encoding = "39"
      p.create
    end
  end
  def user_key_codes(fname,name)
    codes = []
    puts "Starting: " + fname
    File.open(fname,'r').each_line do |line|
      parts = line.split("\t")
      puts "Line: " + line
      create(parts[0].gsub("U",""),'upc')
    end
    return
    i = 0
    while not codes.empty? do
    page do |p|
      p.barcodes = codes.slice!(0,12)
      p.table = {:cols => 2, :rows => 8,:top => 1,:left => 1.5, :right => 1.5, :bottom => 2}
      p.page_width = 210
      p.page_height = 297
      p.filename = "#{name}-#{i}.ps"
      p.encoding = "39"
      p.create
    end
    i = i + 1
    end
  end
end
