# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class StockLocationsController < ApplicationController
   before_filter :check_role


  def index
    @stock_locations = @current_vendor.stock_locations.visible.order('created_at DESC').page(params[:page]).per(@current_vendor.pagination)
  end

  def show
    @location = @current_vendor.stock_locations.visible.find_by_id(params[:id])
  end

  def new
    @location = StockLocation.new
  end
  
  def edit
    @location = @current_vendor.stock_locations.visible.find_by_id(params[:id])
  end

  def create
    @location = StockLocation.new(params[:location])
    @location.vendor = @current_vendor
    @location.company = @current_company

    if @location.save
      redirect_to stock_locations_path
    else
      render :new
    end
  end

  def update
    @location = @current_vendor.stock_locations.visible.find_by_id(params[:id])
    if @location.update_attributes(params[:location])
      redirect_to stock_locations_path
    else
      render :edit
    end
  end

  def destroy
    @location = @current_vendor.stock_locations.visible.find_by_id(params[:id])
    @location.hide(@current_user)
    redirect_to stock_locations_path
  end
end
