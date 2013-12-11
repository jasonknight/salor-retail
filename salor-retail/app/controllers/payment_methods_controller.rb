# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaymentMethodsController < ApplicationController
  before_filter :check_role

  def index
    @payment_methods = @current_vendor.payment_methods.visible.page(params[:page]).per(@current_vendor.pagination).order('name ASC')
  end

  def show
    @payment_method = @current_vendor.payment_methods.visible.find_by_id(params[:id])
    redirect_to edit_payment_method_path(@payment_method)
  end

  
  def new
    @payment_method = PaymentMethod.new
  end

  def edit
    @payment_method = @current_vendor.payment_methods.visible.find_by_id(params[:id])
  end

  def create
    @payment_method = PaymentMethod.new(params[:payment_method])
    @payment_method.vendor = @current_vendor
    @payment_method.company = @current_company
    if @payment_method.save
      redirect_to payment_methods_path
    else
      render :new
    end
  end

  def update
    @payment_method = @current_vendor.payment_methods.visible.find_by_id(params[:id])
    if @payment_method.update_attributes(params[:payment_method])
      redirect_to payment_methods_path
    else
      render :edit
    end
  end

  def destroy
    @payment_method = @current_vendor.payment_methods.visible.find_by_id(params[:id])
    @payment_method.hide(@current_user)
    redirect_to payment_methods_path
  end
end
