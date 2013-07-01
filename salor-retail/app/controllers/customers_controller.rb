# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class CustomersController < ApplicationController

  before_filter :check_role
  
  def download
    @customers = @current_vendor.customers.visible
    data = render_to_string :layout => false
    send_data(data,:filename => 'customers.csv', :type => 'text/csv')
  end
  
  def index
    CashRegister.update_all_devicenodes
    @customers = @current_company.customers.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end

  def new
    @customer = Customer.new
    @customer.loyalty_cards.build
    @customer.notes.build
  end

  def show
    @customer = @current_company.customers.visible.find_by_id(params[:id])
    @item_statistics = @customer.get_item_statistics
    @last_orders = @customer.orders.limit(5).reverse
  end

  def edit
    @customer = @current_company.customers.visible.find_by_id(params[:id])
    if @customer.loyalty_cards.empty? then
      @customer.loyalty_cards.build
    end
    if @customer.notes.empty? then
      @customer.notes.build
    end
  end

  def create
    @customer = Customer.new(params[:customer])
    @customer.vendor = @current_vendor
    @customer.company = @current_company
    if @customer.save
      redirect_to customers_path
    else
      render :new
    end
  end

  def update
    @customer = @current_company.customers.visible.find_by_id(params[:id])
    if @customer.update_attributes(params[:customer])
      redirect_to customers_path
    else
      render :edit
    end
  end

  def destroy
    @customer = @current_company.customers.visible.find_by_id(params[:id])
    @customer.hide(@current_user)
    redirect_to customers_path
  end

  def labels
    if params[:user_type] == 'User'
      @user = User.find_by_id(params[:user_id])
    else
      @user = User.find_by_id(params[:user_id])
    end
    @register = CashRegister.find_by_id(params[:current_register_id])
    @vendor = @register.vendor if @register
    #`espeak -s 50 -v en "#{ params[:current_register_id] }"`
    render :nothing => true and return if @register.nil? or @vendor.nil? or @user.nil?

    @customers = Customer.find_all_by_id(params[:id])
    
    template = File.read("#{Rails.root}/app/views/printr/#{params[:type]}.prnt.erb")
    erb = ERB.new(template, 0, '>')
    text = erb.result(binding)
    if @register.salor_printer
      render :text => Escper::Asciifier.new.process(text)
    else
      printer_path = params[:type] == 'lc_sticker' ? @register.sticker_printer : @register.thermal_printer
      vendor_printer = VendorPrinter.new :path => printer_path
      print_engine = Escper::Printer.new('local', vendor_printer)
      print_engine.open
      print_engine.print(0, text)
      print_engine.close
      render :nothing => true
    end
  end

  def upload_optimalsoft
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type4(lines)
      redirect_to(:action => 'index')
    else
      redirect_to :controller => 'items', :action => 'upload'
    end
  end
end
