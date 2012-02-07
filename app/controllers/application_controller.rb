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

class ApplicationController < ActionController::Base
  include SalorBase
  helper :all
  helper_method :workstation?, :mobile?
  protect_from_forgery
  before_filter :loadup, :except => [:load_clock, :add_item_ajax]
  before_filter :setup_global_data, :except => [:load_clock]
  layout :layout_by_response
  helper_method [:user_cache_name]
  def render_csv(filename = nil,text = nil)
    filename ||= params[:action]
    filename += '.csv'
  
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain" 
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" 
      headers['Expires'] = "0" 
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
    end  
    if text then
      render :text => text
    else
      render :layout => false
    end
  end

  def workstation?
    false #request.user_agent.nil? or request.user_agent.include?('Firefox') or request.user_agent.include?('MSIE') or request.user_agent.include?('Macintosh') or request.user_agent.include?('Chrom') or request.user_agent.include?('iPad') or request.user_agent.include?('Qt/4.7')
  end

  def mobile?
    not workstation?
  end

  def salor_signed_in?
    if session[:user_id] and session[:user_type] then
      return true
    else
      return false
    end
  end
  def admin_signed_in?
    if session[:user_id] and session[:user_type] == "User" then
      return true
    else
      return false
    end
  end
  def current_user
    return User.find session[:user_id] if session[:user_type] == "User"
  end
  def salor_user
    if session[:user_id] then
      if session[:user_type] == "User" then
        return User.find session[:user_id]
      else
        return Employee.find session[:user_id]
      end
    end
  end

  def user_cache_name
    return salor_user.username if salor_signed_in?
    return 'loggedout'
  end

  def load_clock
    render :layout => false
  end

  private
  def allowed_klasses
    ['LoyaltyCard','Item','ShipmentItem','Vendor','Category','Location','Shipment','Order','OrderItem','CashRegisterDaily']
  end
  def initialize_instance_variables
    if params[:vendor_id] and not params[:vendor_id].blank? then
      salor_user.meta.update_attribute(:vendor_id,params[:vendor_id])
    end
    if salor_user.meta.vendor_id.nil? then
      salor_user.meta.update_attribute(:vendor_id,salor_user.get_default_vendor.id)
    end
    if params[:cash_register_id] then
      salor_user.meta.update_attribute(:cash_register_id,params[:cash_register_id])
    end
    if salor_user then
	    @tax_profiles = salor_user.get_tax_profiles
	    if salor_user.meta.cash_register_id then
	      @cash_register = CashRegister.find_by_id(salor_user.meta.cash_register_id)
	    else
	      @cash_register = CashRegister.new(:name => 'Unk')
	    end
	    $Register = @cash_register
	    GlobalData.cash_register = @cash_register
	    if Vendor.exists?(salor_user.meta.vendor_id) then
	       @vendor = Vendor.find(salor_user.meta.vendor_id)
	    else 
	       @vendor = Vendor.new
	       @vendor.name = I18n.t("views.errors.unknown_vendor")
	    end
    end
    GlobalData.vendor = @vendor
    $Vendor = @vendor
    GlobalData.conf = @vendor.salor_configuration if @vendor
    if @vendor then 
      $Conf = @vendor.salor_configuration
    end
  end
  def layout_by_response
    if params[:ajax] then
       return false
    end
    return "application"
  end
  def loadup
    SalorBase.log_action("ApplicationController.loadup","--- New Request -- \n" + params.inspect)
    GlobalData.refresh # Because classes are cached across requests
	  I18n.locale = AppConfig.locale
	  Job.run # Cron jobs for the application
	  GlobalData.base_locale = AppConfig.base_locale
	  if salor_signed_in? then
      I18n.locale = salor_user.language
		  @owner = salor_user.get_owner
		  if salor_user.meta.nil? then
        salor_user.meta = Meta.new
        salor_user.meta.save
      end
    else 
      @owner = User.new
    end
    
    add_breadcrumb I18n.t("menu.home"),'home_user_employee_index_path'
    @page_title = "Salor"
    @page_title_options = {}
  end

  protected
  def authify
    if not salor_signed_in? then
      # puts  "Not Signed in..";
      redirect_to '/home/index' and return
    end
    return true
  end
  def add_breadcrumb(name, url = '')
    begin
    @breadcrumbs ||= []
      url = eval(url) if url =~ /_path|_url|@/
      @breadcrumbs << [name, url]
    rescue

    end
  end
 
  def self.add_breadcrumb(name, url, options = {})
    before_filter options do |controller|
      controller.send(:add_breadcrumb, name, url)
    end
  end
  def initialize_order
    if params[:order_id] then
      o = Order.scopied.where("id = #{params[:order_id]} and (paid IS NULL or paid = 0)").first
      # puts  "!!!!!!!! Found order from params!"
      $User.get_meta.update_attribute :order_id, o.id
      return o if o
    end
    if not GlobalData.salor_user.meta.order_id or not Order.exists? GlobalData.salor_user.meta.order_id then
      order = GlobalData.salor_user.get_new_order
      GlobalData.salor_user.meta.update_attribute(:order_id,order.id)
    else
      order = GlobalData.salor_user.get_order(GlobalData.salor_user.meta.order_id)
    end
    return order
  end
  #
  def setup_global_data
    vars = {}
    var_names = [:vendor_id,:order_id,:cash_register_id]
    var_names.each do |var|
      if session[var].nil? then
        vars[var.to_s] = params[var]
      else
        vars[var.to_s] = session[var]
      end
    end
    
    GlobalData.session = vars
    GlobalData.request = request
    vars = {}
    var_names = [:no_inc,:sku,:controller,:action,:page,:vendor_id,:keywords]
    var_names.each do |var|
      vars[var.to_s] = params[var] 
    end
    
    GlobalData.params = vars
    if salor_user
      GlobalData.salor_user = salor_user
      GlobalData.cash_register = @cash_register
      GlobalData.user_id = salor_user.get_owner.id
      $User = salor_user
      $Meta = salor_user.get_meta
      tps = salor_user.get_tax_profiles
      if tps.any? then
        GlobalData.tax_profiles = tps
      else
        GlobalData.tax_profiles = nil
      end
    end
  end
  def check_role
    if not role_check(params) then 
      redirect_to(role_check_failed) and return
    end  
  end
  def role_check_failed
    return salor_user.get_root.merge({:notice => I18n.t("system.errors.no_role")})
  end
  
  def role_check(p)
    return true if AppConfig.roleless == true
    return salor_user.can(p[:action] + '_' + p[:controller])
  end
  
  def check_license()
    return true
  end
  def assign_from_to(p)
    begin
      f = Date.civil( p[:from][:year ].to_i,
                      p[:from][:month].to_i,
                      p[:from][:day  ].to_i) if p[:from]
      t = Date.civil( p[:to  ][:year ].to_i,
                      p[:to  ][:month].to_i,
                      p[:to  ][:day  ].to_i) if p[:to]
    rescue
      f = t = nil
    end

    f ||= 0.day.ago
    t ||= 0.day.ago
    return f, t
  end
  def time_from_to(p)
    begin
      f = DateTime.civil( p[:from][:year ].to_i,
                      p[:from][:month].to_i,
                      p[:from][:day  ].to_i,
                      p[:from][:hour  ].to_i,
                      p[:from][:minute  ].to_i,0) if p[:from]
      t = DateTime.civil( p[:to  ][:year ].to_i,
                      p[:to  ][:month].to_i,
                      p[:to  ][:day  ].to_i,
                      p[:to][:hour  ].to_i,
                      p[:to][:minute  ].to_i,0) if p[:to]
    rescue
      f = t = nil
    end

    f ||= 0.day.ago
    t ||= 0.day.ago
    return f, t
  end

end
