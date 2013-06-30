# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ShippersController < ApplicationController

  before_filter :check_role

  def index
    @shippers = @current_vendor.shippers.visible.order("name asc").page(params[:page]).per(@current_vendor.pagination)
  end

  def show
    @shipper = @current_vendor.shippers.visible.find_by_id(params[:id])
    redirect_to edit_shipper_path(@shipper)
  end

  def new
    @shipper = Shipper.new
  end

  def edit
    @shipper = @current_vendor.shippers.visible.find_by_id(params[:id])
  end

  def create
    @shipper = Shipper.new(params[:shipper])
    @shipper.vendor = @current_vendor
    @shipper.company = @current_company

    if @shipper.save
      redirect_to shippers_path
    else
      render :new
    end
  end

  def update
    @shipper = @current_vendor.shippers.visible.find_by_id(params[:id])

    if @shipper.update_attributes(params[:shipper])
      redirect_to shippers_path
    else
      render :edit
    end
  end

  def destroy
    @shipper = @current_vendor.shippers.visible.find_by_id(params[:id])
    @shipper.hide(@current_user)
  end
end
