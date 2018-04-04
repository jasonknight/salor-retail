# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class SessionsController < ApplicationController
  
  skip_before_filter :fetch_current_user, :only => [:new, :create]
  skip_before_filter :get_cash_register, :only => [:new, :create]
  
  def new
    @submit_path = session_path
    @company = Company.visible.first
    @vendor = @company.vendors.visible.first
    redirect_to sr_saas.new_session_path and return if defined?(SrSaas) == 'constant'
  end

  def create
    # Simple local login
    company = Company.visible.first
    user = company.login(params[:code])

    if user
      vendor = user.vendors.visible.first
      session[:user_id_hash] = user.id_hash
      session[:company_id] = company.id
      session[:vendor_id] = vendor.id
      session[:locale] = I18n.locale = user.language
      
      user.sign_in_count += 1
      user.current_sign_in_at = Time.now
      user.current_sign_in_ip = request.ip
      user.save
      
      if vendor.enable_technician_emails and vendor.technician_email and company.mode == 'demo' and SalorRetail::Application::SR_DEBIAN_SITEID != 'none'
        UserMailer.technician_message(vendor, "Login to #{ company.name }", '', request).deliver
      end
      $MESSAGES[:notices] << "Welcome, #{ user.username }! ☺"
      redirect_to root_path and return
    else
      $MESSAGES[:alerts] << "Wrong login ☹"
      redirect_to new_session_path and return
    end
  end
  
  def destroy
    if @current_user
      @current_user.end_day
      @current_user.last_sign_in_at = @current_user.current_sign_in_at
      @current_user.last_sign_in_ip = @current_user.current_sign_in_ip
      @current_user.current_sign_in_at = nil
      @current_user.current_sign_in_ip = nil
      @current_user = nil
      [:user_id_hash, :vendor_id, :company_id, :locale].each do |k|
        session[k] = nil
      end
    end
    redirect_to '/'
  end

  def test_exception
    nil.throw_whiny_nil_error # this method does not exist, which throws an exception.
  end
  
  def email
    subject = params[:s]
    subject ||= "Test"
    message = params[:m]
    message ||= "Message"
    vendor = Vendor.find_by_id(session[:vendor_id])
    if vendor and vendor.technician_email and vendor.enable_technician_emails
      UserMailer.technician_message(vendor, subject, message).deliver
    else
      logger.info "[TECHNICIAN] #{subject} #{message}"
    end
    render :nothing => true
  end
  
  def test_email
    subject = params[:s]
    subject ||= "Test"
    message = params[:m]
    message ||= "Message"
    company = Company.find_by_id(session[:company_id])
    vendor = Vendor.find_by_id(session[:vendor_id])
    if vendor and vendor.technician_email and vendor.enable_technician_emails
      UserMailer.technician_message(vendor, subject, message).deliver
    else
      logger.info "[TECHNICIAN] #{subject} #{message}"
    end
    redirect_to '/'
  end

  def catcher
    redirect_to 'new'
  end
  
  def remote_service
    redirect_to '/' if @current_company.mode != 'local'
  end
  
  def update_connection_status
    render :nothing => true and return if @current_company.mode != 'local'
    @status_ssh = not(`netstat -pna | grep :26`.empty?)
    @status_vnc = not(`netstat -pna | grep :28`.empty?)
    #@status_ssh = false
    #@status_vnc = false
    render :js => "connection_status = {ssh:#{@status_ssh}, vnc:#{@status_vnc}};"
  end

  def connect_remote_service
    render :nothing => true and return if @current_company.mode != 'local'
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
        spawn "expect /usr/share/remotesupport/remotesupportvnc.expect #{ params[:host] } #{ params[:user] } #{ params[:pw] }", :out => "/tmp/salor-hospitality-x11vnc-stdout.log", :err => "/tmp/salor-hospitality-x11vnc-stderr.log"
      end
    end
    render :nothing => true
  end
 
end
