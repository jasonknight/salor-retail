# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class CashRegistersController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  before_filter :set_devicenodes
  # GET /cash_registers
  # GET /cash_registers.xml
  def index
    @cash_registers = CashRegister.scopied.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cash_registers }
    end
  end

  # GET /cash_registers/1
  # GET /cash_registers/1.xml
  def show
    @cash_register = CashRegister.scopied.find(params[:id])
    @orders = @cash_register.orders.order(AppConfig.orders.order).scopied.page(params[:page]).per(GlobalData.conf.pagination)
    add_breadcrumb @cash_register.name,'cash_register_path(@cash_register,:vendor_id => params[:vendor_id])'
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cash_register }
    end
  end

  # GET /cash_registers/new
  # GET /cash_registers/new.xml
  def new
    @cash_register = CashRegister.scopied.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cash_register }
    end
  end

  # GET /cash_registers/1/edit
  def edit
    @cash_register = CashRegister.scopied.find(params[:id])
    add_breadcrumb @cash_register.name,'edit_cash_register_path(@cash_register,:vendor_id => params[:vendor_id])'
    set_devicenodes
  end

  # POST /cash_registers
  # POST /cash_registers.xml
  def create
    @cash_register = CashRegister.new(params[:cash_register])
 
    respond_to do |format|
      if @cash_register.save
        @cash_register.set_model_owner(salor_user)
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => CashRegister.model_name.human)) }
        format.xml  { render :xml => @cash_register, :status => :created, :location => @cash_register }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cash_register.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cash_registers/1
  # PUT /cash_registers/1.xml
  def update
    @cash_register = CashRegister.scopied.find(params[:id])

    respond_to do |format|
      if @cash_register.update_attributes(params[:cash_register])
        format.html { render :action => 'edit', :notice => 'Cash register was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cash_register.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cash_registers/1
  # DELETE /cash_registers/1.xml
  def destroy
    @cash_register = CashRegister.scopied.find(params[:id])
    if @cash_register.orders.any? then
      @cash_register.update_attribute(:hidden,1)
      if @cash_register.id == salor_user.meta.cash_register_id then
        salor_user.meta.cash_register_id = nil
      end
    else
      if @cash_register.id == salor_user.meta.cash_register_id then
        salor_user.meta.cash_register_id = nil
      end
      @cash_register.kill
    end
    
    respond_to do |format|
      format.html { redirect_to(cash_registers_url) }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = $Vendor
    add_breadcrumb @vendor.name,'vendor_path(@vendor)' if @vendor.id
    add_breadcrumb I18n.t("menu.cash_registers"),'cash_registers_path(:vendor_id => params[:vendor_id])'
  end
  
  def set_devicenodes
    nodes_usb1 = Dir['/dev/usb/lp*']
    nodes_usb2 = Dir['/dev/usblp*']
    nodes_serial = Dir['/dev/usb/ttyUSB*']
    nodes_salor = Dir['/dev/salor*']
    all_nodes = nodes_usb1 + nodes_usb2 + nodes_serial + nodes_salor
    @devicenodes = {}
    all_nodes.each do |n|
      # the following unfortunately doesn't work in production
      #devicename = `udevadm info -a -p  $(udevadm info -q path -n #{n}) | grep ieee1284_id`
      #devicename = /^.*L:(.*?)\;.*/.match(devicename)[1]
      #full_devicename = "#{n}: #{devicename}"
      #@devicenodes.merge! full_devicename => n
      @devicenodes.merge! n => n
    end
    @devicenodes = @devicenodes.to_a
  end
end
