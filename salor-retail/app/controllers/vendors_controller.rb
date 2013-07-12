# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class VendorsController < ApplicationController
  
  after_filter :customerscreen_push_notification, :only => [:edit_field_on_child]

  # TODO: This needs to be scoped for SAAS
  def csv
    @vendor = Vendor.find_by_token(params[:token])
    if @vendor then
      @items = Item.where(["vendor_id =? and hidden != 1",@vendor.id])
      @categories = Category.where(["vendor_id =? and hidden != 1",@vendor.id])
      @buttons = Button.where(["vendor_id =? and hidden != 1",@vendor.id]) if @vendor.salor_configuration.csv_buttons
      @discounts = Discount.where(["vendor_id =? and hidden IS FALSE OR hidden IS NULL",@vendor.id]) if @vendor.salor_configuration.csv_discounts
      @customers = Customer.where(["vendor_id =? and hidden != 1",@vendor.id]) if @vendor.salor_configuration.csv_customers
    end
    render :layout => false
  end
  
  def index
    @vendors = @current_user.vendors.visible
  end

  def show
    @vendor = @current_user.vendors.visible.find_by_id(params[:id])
    session[:vendor_id] = @vendor.id
  end

  def new
    @vendor = Vendor.new
  end

  def edit
    @vendor = @current_user.vendors.visible.find_by_id(params[:id])
    session[:vendor_id] = @vendor.id
  end

  def create
    @vendor = Vendor.new(params[:vendor])
    @vendor.company = @current_company
    @vendor.users = [@current_user]
    if @vendor.save
      redirect_to vendors_path
    else
      render :new
    end
  end


  def update
    @vendor = @current_user.vendors.visible.find_by_id(params[:id])
    if @vendor.update_attributes(params[:vendor])
      redirect_to vendor_path(@vendor)
    else
      render :edit
    end
  end


  def new_drawer_transaction
    user = @current_vendor.users.visible.find_by_id(params[:user_id])
    @drawer = user.get_drawer
    
    @dt = DrawerTransaction.new
    @dt.vendor = @current_vendor
    @dt.company = @current_company
    @dt.drawer_amount = @drawer.amount
    @dt.drawer = @drawer
    @dt.user = user
    @dt.amount = SalorBase.string_to_float(params[:transaction][:amount])
    @dt.tag = params[:transaction][:tag]
    @dt.notes = params[:transaction][:notes]
    @dt.cash_register = @current_register
    if params[:transaction][:trans_type] == "payout"
      @dt.amount *= -1
    end
    ret = @dt.save
    raise "Failed to save drawer transaction" unless ret == true
    @drawer.amount += @dt.amount
    @drawer.save
  end

  def open_cash_drawer
    @current_register.open_cash_drawer
    render :nothing => true
  end
  
  def render_open_cashdrawer
    render :text => @current_register.open_cash_drawer_code
  end

  def render_drawer_transaction_receipt
    @dt = @current_vendor.drawer_transactions.visible.find_by_id(params[:id])
    if @current_register.salor_printer
      text = @dt.escpos
      render :text => Escper::Asciifier.new.process(text)
    else
      text = @dt.print
      render :nothing => true
    end
    r = Receipt.new
    r.vendor = @current_vendor
    r.company = @current_company
    r.cash_register = @current_register
    r.user = @current_user
    r.drawer = @current_user.get_drawer
    r.content = text
    r.ip = request.ip
    r.save
  end
  
  def report_day
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : Time.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    @users = @current_vendor.users.visible
    @user = @current_vendor.users.visible.find_by_id(params[:user_id])
    @user ||= @current_user
    @report = @current_vendor.get_end_of_day_report(@from, @to, @user.get_drawer)
  end


  def render_report_day
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : Time.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    @user = @current_vendor.users.visible.find_by_id(params[:user_id])
    
    if @current_register.salor_printer
      text = @current_vendor.escpos_eod_receipt(@from, @to, @user.get_drawer)
      render :text => Escper::Asciifier.new.process(text)
      return
    else
      text = @current_vendor.print_eod_report(@from, @to, @user.get_drawer, @current_register)
      render :nothing => true
    end
    
    r = Receipt.new
    r.vendor = @current_vendor
    r.company = @current_company
    r.cash_register = @current_register
    r.user = @current_user
    r.drawer = @current_user.get_drawer
    r.content = text
    r.ip = request.ip
    r.save
  end
  
  def edit_field_on_child
    klass = params[:klass].constantize
    @inst = klass.where(:vendor_id => @current_vendor).find_by_id(params[:id])
      
    if @inst.class == Order
      @order = @inst
    elsif @inst.class == OrderItem
      @order = @inst.order
    end

    #value = SalorBase.string_to_float(params[:value])
    value = params[:value]
    if @inst.respond_to?("#{ params[:field] }=".to_sym)
      @inst.send("#{ params[:field] }=", value)
      @inst.save
    else
      raise "VendorsController#edit_field_on_child: #{ klass } does not respond well to setter method #{ params[:field] }!"
    end
    
    if @inst.class == OrderItem
      @inst.calculate_totals
      @order.calculate_totals
      render 'orders/update_pos_display'
    elsif @inst.class == Order
      @inst.calculate_totals
      render 'orders/update_pos_display'
    else
      render :nothing => true
    end
  end

  def history
    @histories = @current_vendor.histories.order("created_at desc").page(params[:page]).per(@current_vendor.pagination)
  end
  
  def statistics
    f, t = assign_from_to(params)
    params[:limit] ||= 15
    @limit = params[:limit].to_i - 1
    
    @reports = @current_vendor.get_statistics(f, t)
    
    view = SalorRetail::Application::CONFIGURATION[:reports][:style]
    view ||= 'default'
    render "/vendors/reports/#{view}/page"
  end
  
  def export
    if params[:file] then
      manager = CsvManager.new(params[:file],"\t")
      if params[:do_what] == 'download' then
        output = manager.route(params)
        send_csv(output,params[:download_type] + '_Download') and return
      else
        output = manager.send params[:do_what]
        no = output[:successes].join "\n"
        no = no + "\n" + output[:errors].join("\n")
        send_csv(no,params[:do_what]) and return
      end
    end
  end

  def labels
    render :layout => false    
  end
  
  def display_logo
    render :layout => 'customer_display'
  end
  
  def backup
    configpath = SalorRetail::Application::SR_DEBIAN_SITEID == 'none' ? 'config/database.yml' : "/etc/salor-retail/#{SalorRetail::Application::SR_DEBIAN_SITEID}/database.yml"
    dbconfig = YAML::load(File.open(configpath))
    mode = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
    username = dbconfig[mode]['username']
    password = dbconfig[mode]['password']
    database = dbconfig[mode]['database']
    `mysqldump -u #{username} -p#{password} #{database} | bzip2 -c > #{Rails.root}/tmp/backup-#{$Vendor.id}.sql.bz2`

    send_file("#{Rails.root}/tmp/backup-#{$Vendor.id}.sql.bz2",:type => :bzip,:disposition => "attachment",:filename => "backup-#{$Vendor.id}.sql.bz2")
  end


  private

  def send_csv(lines,name)
    ftype = 'tsv'
    send_data(lines, :filename => "#{name}_#{Time.now.year}#{Time.now.month}#{Time.now.day}-#{Time.now.hour}#{Time.now.min}.#{ftype}", :type => 'application-x/csv') and return
	end
	# {END}
end
