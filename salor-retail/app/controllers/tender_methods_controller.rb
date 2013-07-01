# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class TenderMethodsController < ApplicationController
  before_filter :check_role

  def index
    @tender_methods = @current_vendor.tender_methods.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end

  def show
    @tender_method = @current_vendor.tender_methods.visible.find_by_id(params[:id])
    redirect_to edit_tender_method_path(@tender_method)
  end

  
  def new
    @tender_method = TenderMethod.new
  end

  def edit
    @tender_method = @current_vendor.tender_methods.visible.find_by_id(params[:id])
  end

  def create
    @tender_method = TenderMethod.new(params[:tender_method])
    @tender_method.vendor = @current_vendor
    @tender_method.company = @current_company
    if @tender_method.save
      redirect_to tender_methods_path
    else
      render :new
    end
  end

  def update
    @tender_method = @current_vendor.tender_methods.visible.find_by_id(params[:id])
    if @tender_method.update_attributes(params[:tender_method])
      redirect_to tender_methods_path
    else
      render :edit
    end
  end

  def destroy
    @tender_method = @current_vendor.tender_methods.visible.find_by_id(params[:id])
    @tender_method.hide(@current_user)
    redirect_to tender_methods_path
  end
end
