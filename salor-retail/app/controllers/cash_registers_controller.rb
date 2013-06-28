# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class CashRegistersController < ApplicationController
  before_filter :get_devicenodes

  def index
    @registers = CashRegister.scopied.page(params[:page])
    CashRegister.update_all_devicenodes
  end


  
  def show
    if params[:id]
      session[:cash_register_id] = params[:id]
    end
    redirect_to new_order_path
  end

  # GET /current_registers/new
  # GET /current_registers/new.xml
  def new
    @current_register = CashRegister.scopied.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @current_register }
    end
  end

  # GET /current_registers/1/edit
  def edit
    @current_register = CashRegister.scopied.find(params[:id])
  end

  # POST /current_registers
  # POST /current_registers.xml
  def create
    @current_register = CashRegister.new(params[:current_register])
 
    respond_to do |format|
      if @current_register.save
        @current_register.set_model_owner(@current_user)
        format.html { redirect_to current_registers_path }
        format.xml  { render :xml => @current_register, :status => :created, :location => @current_register }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @current_register.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /current_registers/1
  # PUT /current_registers/1.xml
  def update
    @current_register = CashRegister.scopied.find(params[:id])
    respond_to do |format|
      if @current_register.update_attributes(params[:current_register])
         @current_register.thermal_printer_name = nil unless params[:current_register][:thermal_printer].empty?
         @current_register.sticker_printer_name = nil unless params[:current_register][:sticker_printer].empty?
         @current_register.scale_name = nil unless params[:current_register][:scale_name].empty?
        @current_register.save
        format.html { redirect_to current_registers_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @current_register.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /current_registers/1
  # DELETE /current_registers/1.xml
  def destroy
    @current_register = CashRegister.scopied.find(params[:id])
    if @current_register.orders.any? then
      @current_register.update_attribute(:hidden,1)
      if @current_register.id == @current_register then
        @current_register = nil
      end
    else
      if @current_register.id == @current_register then
        @current_register = nil
      end
      @current_register.kill
    end
    
    respond_to do |format|
      format.html { redirect_to(current_registers_url) }
      format.xml  { head :ok }
    end
  end
  private 
  
  def get_devicenodes
    @devices_for_select = CashRegister.get_devicenodes
  end

end
