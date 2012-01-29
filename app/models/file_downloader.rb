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
require 'rubygems'
require 'mechanize'
require 'mail'
class FileDownloader
  def initialize(opts=nil)
    set_options(opts)
  end
  def set_options(opts=nil)
    # Set these up in /etc/salor.yml
    opts[:enable_ssl] ||= AppConfig.mail.enable_ssl
    opts[:address] ||= AppConfig.mail.address
    opts[:port] ||= Appconfig.mail.port
    opts[:user_name] ||= AppConfig.mail.user_name
    opts[:password] ||= AppConfig.mail.password
    Mail.defaults do
      retriever_method :pop3, :address    => opts[:address],
                          :port       => opts[:port],
                          :user_name  => opts[:user_name],
                          :password   => opts[:password],
                          :enable_ssl => opts[:enable_ssl]
    end
  end
  def download_all
    if (Time.now - 5.days) > GlobalData.conf.last_wholesaler_check then
      text = tobacco_land
      File.open("#{::Rails.root.to_s}/public/wholesalers/tobacco_land.txt",'wb+') do |f|
        f.write text
      end
      
      text = moosmayr
      File.open("#{::Rails.root.to_s}/public/wholesalers/moosmayr.txt",'wb+') do |f|
        f.write text
      end
      download_wholesalers
      lobalData.conf.update_attribute(:last_wholesaler_check,Time.now)
    end
  end
  def tobacco_land
    a = Mechanize.new
    a.get('http://www.tobaccoland.at/cms/cms.php') do |page|
      # Submit the login form
      page.form_with(:action => '/cms/trafikant_login.php') do |f|
        f.user  = AppConfig.tobacco_land.user
        f.pass  = AppConfig.tobacco_land.pass
      end.click_button
      
      dlpage = a.get("http://www.tobaccoland.at/cms/cms.php?pageName=66")
      file = dlpage.link_with(:text => /soweb_\d{4}-\d{2}-\d{2}.txt/).click
      return file.body
    end
    return ''
  end
  def moosmayr
    a = Mechanize.new
    file = a.get("http://www.moosmayr.at/artikelstammdaten/artikelstammdaten_moosmayr.csv")
    return file if file
    return ''
  end
  def download_wholesalers
    fnames = []
    Mail.all.each do |mail|
      if mail.subject.include? "wholesaler" then
        mail.attachments.each do |attachment|
          fnames << attachment.filename
          File.open("#{::Rails.root.to_s}/public/wholesalers/#{attachment.filename}",'wb+') do |f|
            f.write attachment.decoded
          end
        end
      end
    end
    fnames
  end
end
