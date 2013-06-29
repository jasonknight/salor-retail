# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class HomeController < ApplicationController
  
  skip_before_filter :loadup, :only => :index
  
  def errors_display
    @exception = $!
  end
  
  def exception_test
    nil.whine
  end
  
  def index

  end
  

  def set_language
    if @current_user then
      supported_language.each do |lang|
        if params[:lang] == lang[:locale] then
          @current_user.update_attribute(:language,params[:lang])
        end
      end
    end
  end
  def edit_user
    redirect_to '/current_registers' and return unless admin_signed_in?
    @user = User.find(current_user.id)
  end
  def update_user
    redirect_to '/current_registers' and return unless admin_signed_in?
    @user = User.find(current_user.id)
    params[:user].delete(:password) if params[:user][:password].nil? or params[:user][:password].blank?
    params[:user].delete(:user_id)
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to :action => 'edit_user', :notice => t(:"system.user_success") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_user" }
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


  def update_connection_status
    @status_ssh = not(`netstat -pna | grep :26`.empty?)
    @status_vnc = not(`netstat -pna | grep :28`.empty?)
    #@status_ssh = false
    #@status_vnc = false
    render :js => "connection_status = {ssh:#{@status_ssh}, vnc:#{@status_vnc}};"
  end


  def connect_remote_service
    if params[:type] == 'ssh'
      @status_ssh = `netstat -pna | grep :26`
      if @status_ssh.empty? # don't create more process than one
        connection_thread_ssh = fork do
          exec "expect #{ File.join('/', 'usr', 'share', 'remotesupport', 'remotesupportssh.expect').to_s } #{ params[:host] } #{ params[:user] } #{ params[:pw] }"
        end
        Process.detach(connection_thread_ssh)
      end
    end
    if params[:type] == 'vnc'
      @status_vnc = `netstat -pna | grep :28`
      if @status_vnc.empty? # don't create more process than one
        spawn "expect /usr/share/remotesupport/remotesupportvnc.expect #{ params[:host] } #{ params[:user] } #{ params[:pw] }", :out => "/tmp/salor-retail-x11vnc-stdout.log", :err => "/tmp/salor-retail-x11vnc-stderr.log"
      end
    end
    render :nothing => true
  end
end
