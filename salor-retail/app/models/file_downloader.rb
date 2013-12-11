# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

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
