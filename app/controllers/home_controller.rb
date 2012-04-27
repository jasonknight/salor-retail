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
class HomeController < ApplicationController
  before_filter :authify, :except => [:index, :load_clock,:you_have_to_pay, :remote_service, :connect_remote_service, :get_connection_status]
  before_filter :initialize_instance_variables, :only => [:user_employee_index, :edit_owner, :update_owner, :remote_service, :connect_remote_service, :get_connection_status]
  before_filter :check_role, :only => [:edit_owner, :update_owner], :except => [:remote_service, :connect_remote_service, :get_connection_status]
  def errors_display
    @exception = $!
  end
  def index
    if AppConfig.standalone and User.count == 0 then
      redirect_to new_user_registration_path and return
    end
    @from = Time.now
    @to = Time.now
  end
  def user_employee_index
    Session.sweep
    if not check_license() then
      render :action => "402", :status => 402 and return
    end
    r = salor_user.get_root
    if r then
      redirect_to r and return
    end
  end
  def set_user_theme_ajax
    if admin_signed_in? then
      current_user.set_theme(params[:theme])
    end
    render :layout => false
  end
  def set_language
    if salor_user then
      supported_language.each do |lang|
        if params[:lang] == lang[:locale] then
          salor_user.update_attribute(:language,params[:lang])
        end
      end
    end
  end
  def edit_owner
    redirect_to '/cash_registers' and return unless admin_signed_in?
    @user = User.find(current_user.id)
  end
  def update_owner
    redirect_to '/cash_registers' and return unless admin_signed_in?
    @user = User.find(current_user.id)
    params[:user].delete(:password) if params[:user][:password].nil? or params[:user][:password].blank?
    params[:user].delete(:user_id)
    atomize_all
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to :action => 'edit_owner', :notice => t(:"system.owner_success") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_owner" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  #
  def backup_database
    dbconfig = YAML::load(File.open('config/database.yml'))
    mode = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
    username = dbconfig[mode]['username']
    password = dbconfig[mode]['password']
    database = dbconfig[mode]['database']
    `mysqldump -u #{username} -p#{password} #{database} > tmp/backup.sql`
    send_file 'tmp/backup.sql', :filename => "salor-backup-#{ l Time.now, :format => :datetime_iso2 }.sql"
  end

  #
  def backup_logfile
    send_file 'log/production.log', :filename => "salor-logfile-#{ l Time.now, :format => :datetime_iso2 }.log"
  end

  # this is never called currently. Has been replaced with Salor::JSApi.
  def get_connection_status
    @status_ssh = `netstat -pna | grep :26`
    @status_vpn = `netstat -pna | grep :28`
  end

  # this is never called currently. Has been replaced with Salor::JSApi.
  def connect_remote_service
    if params[:type] == 'ssh'
      @status_ssh = `netstat -pna | grep :26`
      if @status_ssh.empty? # don't create more process than one
        connection_thread_ssh = fork do
          exec "expect #{ File.join('/', 'usr', 'share', 'red-e_ssh_reverse_connect.expect').to_s } #{ params[:host] } #{ params[:user] } #{ params[:pw] }"
        end
        Process.detach(connection_thread_ssh)
      end
    end
    render :nothing => true
  end
end
