# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
require "net/http"
require "uri"
class ApplicationController < ActionController::Base
  # {START}
  include SalorBase
  helper :all
  helper_method :workstation?, :mobile?
  protect_from_forgery
  before_filter :loadup, :except => [:load_clock, :add_item_ajax, :login, :render_error]
  before_filter :pre_load, :except => [:render_error]
  before_filter :setup_global_data, :except => [:login, :render_error]
  layout :layout_by_response
  helper_method [:user_cache_name]

  unless SalorRetail::Application.config.consider_all_requests_local
    rescue_from Exception, :with => :render_error
  end 
  def get_url(url)
    uri = URI.parse(url)
    
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    
    response = http.request(request)
    return response
  end
  def is_mac?
     RUBY_PLATFORM.downcase.include?("darwin")
  end

  def is_windows?
     RUBY_PLATFORM.downcase.include?("mswin")
  end

  def is_linux?
     RUBY_PLATFORM.downcase.include?("linux")
  end   
  def pre_load
  end
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
    request.user_agent.nil? or request.user_agent.include?('Firefox') or request.user_agent.include?('MSIE') or request.user_agent.include?('Macintosh') or request.user_agent.include?('Chrom') or request.user_agent.include?('iPad') or request.user_agent.include?('Qt/4')
  end

  def mobile?
    not workstation?
  end

  def salor_signed_in?
    if session[:user_id] and session[:user_type] and (Employee.exists? session[:user_id] or User.exists? session[:user_id]) then
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
        user= User.find_by_id(session[:user_id].to_i)
      else
        user= Employee.find_by_id(session[:user_id])
        $Vendor = user.vendor if user #Because Global State is maintained across requests.
        
        $User = user
      end
      return user
    end
    return nil
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
    if salor_user and salor_user.meta.vendor_id.nil? then
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
    @current_vendor = @vendor
    @current_employee = $User	
    GlobalData.conf = @vendor.salor_configuration if @vendor
    if @vendor then 
      $Conf = @vendor.salor_configuration
    end
    if !$Conf then
      $Conf = Vendor.first.salor_configuration
    end
  end

  def layout_by_response
    if params[:ajax] then
       return false
    end
    return "application"
  end
  
  def loadup
    $Notice = ""
    SalorBase.log_action("ApplicationController.loadup","--- New Request -- \n" + params.inspect)
    GlobalData.refresh # Because classes are cached across requests
	  Job.run # Cron jobs for the application
	  GlobalData.base_locale = AppConfig.base_locale
    I18n.locale = AppConfig.locale
    
    if params[:license_accepted].to_s == "true" then
      Vendor.first.salor_configuration.update_attribute :license_accepted, true
    end
	  if salor_signed_in? and salor_user then
      I18n.locale = salor_user.language
		  @owner = salor_user.get_owner
		  if salor_user.meta.nil? then
        salor_user.meta = Meta.new
        salor_user.meta.save
      end
    else 
      $User = nil # $User is being set somewhere before this is even called, which is weird.
      @owner = User.new
    end
    I18n.locale = params[:locale] if params[:locale]
    add_breadcrumb I18n.t("menu.home"),'home_user_employee_index_path'
    @page_title = "Salor"
    @page_title_options = {}
  end

  protected

  def render_error(exception)
    #log_error(exception)
    @exception = exception
    if SalorRetail::Application::CONFIGURATION[:exception_notification] == true
      if notifier = Rails.application.config.middleware.detect { |x| x.klass == ExceptionNotifier }
        env['exception_notifier.options'] = notifier.args.first || {}                   
        ExceptionNotifier::Notifier.exception_notification(env, exception).deliver
        env['exception_notifier.delivered'] = true
      end
    end
    render :template => '/errors/error', :layout => 'customer_display'
  end

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
    $Request = request
    $Params = params
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
      $Vendor = $User.vendor
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
    return $User.can(p[:action] + '_' + p[:controller])
  end
  
  # TODO: Remove method check_license since no longer used
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
#       f = t = nil
      
    end
    f ||= DateTime.now.beginning_of_day
    t ||= DateTime.now.end_of_day
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
  # {END}
end
