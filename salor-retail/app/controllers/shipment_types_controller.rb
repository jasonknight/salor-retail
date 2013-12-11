# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ShipmentTypesController < ApplicationController
  before_filter :check_role

  
  def index
    @shipment_types = @current_vendor.shipment_types.visible.page(params[:page]).per(@current_vendor.pagination).order("created_at DESC")
  end

  def show
    @shipment_type = @current_vendor.shipment_types.visible.find_by_id(params[:id])
    redirect_to edit_shipment_type_path(@shipment_type)
  end

  def new
    @shipment_type = ShipmentType.new
  end

  def edit
    @shipment_type = @current_vendor.shipment_types.visible.find_by_id(params[:id])
  end

  def create
    @shipment_type = ShipmentType.new(params[:shipment_type])
    @shipment_type.vendor = @current_vendor
    @shipment_type.company = @current_company
    
    if @shipment_type.save
      redirect_to shipment_types_path
    else
      render :new
    end
  end

  def update
    @shipment_type = @current_vendor.shipment_types.visible.find_by_id(params[:id])
    if @shipment_type.update_attributes(params[:shipment_type])
      redirect_to shipment_types_path
    else
      render :edit
    end
  end

  def destroy
    @shipment_type = @current_vendor.shipment_types.visible.find_by_id(params[:id])
    @shipment_type.hide(@current_user)
    redirect_to shipment_types_path
  end
end
