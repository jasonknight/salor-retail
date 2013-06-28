# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ShipmentsController < ApplicationController
  # {START}
  before_filter :check_role, :except => [:crumble, :move_all_to_items, :move_shipment_item]
  before_filter :crumble
  # GET /shipments
  # GET /shipments.xml
  def index
  @shipments = Shipment.scopied.page(params[:page]).per(30).order('created_at desc')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @shipments }
    end
  end

  # GET /shipments/1
  # GET /shipments/1.xml
  def show
    @shipment = Shipment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @shipment }
    end
  end

  # GET /shipments/new
  # GET /shipments/new.xml
  def new
    @shipment = Shipment.new
    @shipment.receiver_id = $Vendor.id
    @shipment.receiver_type = 'Vendor'
    @shipment_types = ShipmentType.scopied.order(:name)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @shipment }
    end
  end

  # GET /shipments/1/edit
  def edit
    @shipment = Shipment.find(params[:id])
    @shipment_types = ShipmentType.scopied.order(:name)
  end

  # POST /shipments
  # POST /shipments.xml
  def create
    @shipment = Shipment.new(params[:shipment])
    @shipment.shipment_items.update_all :vendor_id => $Vendor.id
    @shipment_types = ShipmentType.scopied.order(:name)
    respond_to do |format|
      if @shipment.save
        format.html { redirect_to(@shipment, :notice => 'Shipment was successfully created.') }
        format.xml  { render :xml => @shipment, :status => :created, :location => @shipment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @shipment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /shipments/1
  # PUT /shipments/1.xml
  def update
    @shipment = Shipment.find(params[:id])
    @shipment_types = ShipmentType.scopied.order(:name)
    respond_to do |format|
      if @shipment.update_attributes(params[:shipment])
        @shipment.shipment_items.update_all :vendor_id => $Vendor.id
        format.html { redirect_to(@shipment, :notice => 'Shipment was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @shipment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /shipments/1
  # DELETE /shipments/1.xml
  def destroy
    @shipment = Shipment.find(params[:id])
    @shipment.kill

    respond_to do |format|
      format.html { redirect_to(shipments_url) }
      format.xml  { head :ok }
    end
  end
  def move_all_to_items
    @shipment = Shipment.find(params[:id])
    if @current_user.owns_this?(@shipment) then
      @shipment.move_all_to_items
      @shipment.save
      redirect_to shipment_path(params[:id], :notice => "Items moved.") and return
    else
      redirect_to shipment_path(params[:id], :notice => "Items not moved.")
    end
    
  end
  def move_shipment_item
    @shipment = Shipment.find(params[:id])
    if @current_user.owns_this?(@shipment) then
      @shipment.move_shipment_item_to_item(params[:shipment_item_id])
      @shipment.save
    end
    @shipment_item = ShipmentItem.scopied.find_by_id(params[:shipment_item_id])
    @item = Item.scopied.find_by_sku(@shipment_item.sku)
  end
  private
    def crumble
      
      add_breadcrumb I18n.t("menu.vendors"),'vendors_path'
      add_breadcrumb @vendor.name,'vendor_path(@vendor)' if @vendor
      add_breadcrumb I18n.t("menu.shipments"),'shipments_path'
    end
  # {END}
end
