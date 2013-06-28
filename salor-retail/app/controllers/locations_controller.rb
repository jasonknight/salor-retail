# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class LocationsController < ApplicationController
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble

  # GET /locations
  # GET /locations.xml
  def index
    @locations = @current_user.get_locations(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @locations }
    end
  end

  # GET /locations/1
  # GET /locations/1.xml
  def show
    @location = Location.by_vendor.find_by_id(params[:id])

    add_breadcrumb @location.name,'location_path(@location,:vendor_id => params[:vendor_id], :type => params[:type])'
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @location }
    end
  end

  # GET /locations/new
  # GET /locations/new.xml
  def new
    @location = Location.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @location }
    end
  end

  # GET /locations/1/edit
  def edit
    @location = @current_user.get_location(params[:id])
    
    add_breadcrumb @location.name,'edit_location_path(@location,:vendor_id => params[:vendor_id], :type => params[:type])'
  end

  # POST /locations
  # POST /locations.xml
  def create
    @location = Location.new(params[:location])

    respond_to do |format|
      if @location.save
        GlobalData.reload(:locations)
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Location.model_name.human)) }
        format.xml  { render :xml => @location, :status => :created, :location => @location }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /locations/1
  # PUT /locations/1.xml
  def update
    @location = @current_user.get_location(params[:id])

    respond_to do |format|
      if @location.update_attributes(params[:location])
        GlobalData.reload(:locations)
        format.html { render :action => 'edit', :notice => I18n.t("views.notice.model_edit", :model => Location.model_name.human) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @location.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /locations/1
  # DELETE /locations/1.xml
  def destroy
    @location = @current_user.get_location(params[:id])
    @location.kill
    GlobalData.reload(:locations)
    respond_to do |format|
      format.html { redirect_to('/locations') }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.locations"),'locations_path(:vendor_id => params[:vendor_id], :type => params[:type])'
  end
end
