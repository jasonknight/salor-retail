# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ShipmentTypesController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /shipment_types
  # GET /shipment_types.xml
  def index
    @shipment_types = GlobalData.salor_user.get_shipment_types

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @shipment_types }
    end
  end

  # GET /shipment_types/1
  # GET /shipment_types/1.xml
  def show
    @shipment_type = ShipmentType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @shipment_type }
    end
  end

  # GET /shipment_types/new
  # GET /shipment_types/new.xml
  def new
    @shipment_type = ShipmentType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @shipment_type }
    end
  end

  # GET /shipment_types/1/edit
  def edit
    @shipment_type = GlobalData.salor_user.get_shipment_type(params[:id])
  end

  # POST /shipment_types
  # POST /shipment_types.xml
  def create
    @shipment_type = ShipmentType.new(params[:shipment_type])
    @shipment_type.set_model_owner
    respond_to do |format|
      if @shipment_type.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => ShipmentType.model_name.human))}
        format.xml  { render :xml => @shipment_type, :status => :created, :location => @shipment_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @shipment_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /shipment_types/1
  # PUT /shipment_types/1.xml
  def update
    @shipment_type = ShipmentType.find(params[:id])

    respond_to do |format|
      if @shipment_type.update_attributes(params[:shipment_type])
        format.html { redirect_to :action => 'index', :notice => I18n.t("views.notice.model_edit", :model => ShipmentType.model_name.human) and return}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @shipment_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /shipment_types/1
  # DELETE /shipment_types/1.xml
  def destroy
    @shipment_type = ShipmentType.find(params[:id])
    @shipment_type.kill

    respond_to do |format|
      format.html { redirect_to(shipment_types_url) }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = GlobalData.salor_user.get_vendor(GlobalData.salor_user.meta.vendor_id)
    add_breadcrumb I18n.t("menu.vendors"),'vendors_path'
    add_breadcrumb @vendor.name,'vendor_path(@vendor)' if @vendor
    add_breadcrumb I18n.t("menu.shipment_types"),'shipment_types_path(:vendor_id => params[:vendor_id])'
  end
end
