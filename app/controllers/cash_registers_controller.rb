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
class CashRegistersController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
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
end
