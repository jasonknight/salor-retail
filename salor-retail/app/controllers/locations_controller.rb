# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class LocationsController < ApplicationController
  before_filter :check_role


  def index
    @locations = @current_vendor.locations.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end

  def show
    @location = @current_vendor.locations.visible.find_by_id(params[:id])
  end

  def new
    @location = Location.new
  end

  def edit
    @location = @current_vendor.locations.visible.find_by_id(params[:id])
  end

  def create
    @location = Location.new(params[:location])
    @location.vendor = @current_vendor
    @location.company = @current_company

    if @location.save
      redirect_to locations_path
    else
      render :new
    end
  end

  def update
    @location = @current_vendor.locations.visible.find_by_id(params[:id])
    if @location.update_attributes(params[:location])
      redirect_to locations_path
    else
      render :edit
    end
  end

  def destroy
    @location = @current_vendor.locations.visible.find_by_id(params[:id])
    @location.hide(@current_user)
    redirect_to locations_path
  end
end
