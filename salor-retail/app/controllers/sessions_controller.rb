# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class SessionsController < ApplicationController
  
  skip_before_filter :loadup, :only => [:new, :create]
  skip_before_filter :get_cash_register, :only => [:new, :create]
  
  def new
    @current_user = session[:user_id_hash] = session[:vendor_id] = session[:company_id] = nil
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
      redirect_to '/' and return
    else
      redirect_to '/' and return
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
 
end
