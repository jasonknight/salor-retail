# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class CashRegistersController < ApplicationController
  before_filter :update_devicenodes, :only => :edit

  def index
    @registers = @current_vendor.cash_registers.visible.page(params[:page]).order("created_at DESC")
    if session[:cash_register_id].blank?
      $MESSAGES[:notices] = I18n.t("notifications.please_select_cash_register")
    end
  end
  
  def show
    session[:cash_register_id] = params[:id]
    redirect_to new_order_path
  end

  def new
    @cash_register = CashRegister.new
    @cash_register.company = @current_company # needed for view
  end

  def edit
    @cash_register = @current_vendor.cash_registers.visible.find_by_id(params[:id])
  end

  def create
    @cash_register = CashRegister.new(params[:cash_register])
    @cash_register.vendor = @current_vendor
    @cash_register.company = @current_company
    if @cash_register.save
      redirect_to cash_registers_path
    else
      render :new
    end
  end

  def update
    @cash_register = @current_vendor.cash_registers.visible.find_by_id(params[:id])
    
    if @cash_register.update_attributes(params[:cash_register])
      redirect_to cash_registers_path
    else
      render :edit
    end
  end

  def destroy
    @cash_register = @current_vendor.cash_registers.visible.find_by_id(params[:id])
    @cash_register.hide(@current_user)
    redirect_to cash_registers_path
  end

end
