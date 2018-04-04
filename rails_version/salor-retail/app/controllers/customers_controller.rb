# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class CustomersController < ApplicationController

  before_filter :check_role, :except => [:info, :search]
  before_filter :update_devicenodes, :only => [:index]
  
  def download
    # @customers = @current_vendor.customers.visible
    # data = render_to_string :layout => false
    # send_data(data,:filename => 'customers.csv', :type => 'text/csv')

    params[:page] ||= 1
    params[:order_by] = "created_at DESC" if not params[:order_by] or params[:order_by].blank?
    orderby ||= params[:order_by]
    if params[:keywords].blank?
      @customers = @current_company.customers.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
    else
      @customers = @current_company.customers.by_keywords(params[:keywords]).visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
    end
    data = render_to_string :layout => false
    send_data(data,:filename => 'customers.csv', :type => 'text/csv')
  end
   def upload
    if params[:file] and params[:file].content_type == "text/csv" then
      shipper = Shipper.new( :name => "Salor")
      shipper.vendor = @current_vendor
      shipper.company = @current_company

      if shipper then
        @uploader = FileUpload.new(shipper, params[:file].read)
        @uploader.salor(true) #i.e. trusted
      end
    end
    render :text => "Done", :status => 200 and return
  end
  
  def index
    if params[:keywords].blank?
      @customers = @current_company.customers.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
    else
      @customers = @current_company.customers.by_keywords(params[:keywords]).visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
    end
  end

  def new
    @customer = Customer.new
    @customer.loyalty_cards.build
    @customer.notes.build
  end

  def show
    @customer = @current_company.customers.visible.find_by_id(params[:id])
    @item_statistics = @customer.get_item_statistics
    @last_orders = @customer.orders.visible.paid.limit(50).order('nr DESC')
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
      @customer.notes.update_all :company_id => @customer.company_id
      redirect_to customers_path
    else
      render :new
    end
  end

  def update
    @customer = @current_company.customers.visible.find_by_id(params[:id])
    if @customer.update_attributes(params[:customer])
      @customer.notes.update_all :company_id => @customer.company_id
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
    output = @current_vendor.print_labels('customer', params, @current_register)
    if params[:download] == 'true'
      send_data output, :filename => '1.salor'
    elsif @current_register.salor_printer
      render :text => output
      return
    end
    render :nothing => true
  end
end
