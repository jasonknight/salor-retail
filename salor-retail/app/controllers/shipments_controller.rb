# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ShipmentsController < ApplicationController

  before_filter :check_role, :except => [:move_all_to_items, :move_shipment_item]

  
  def index
  @shipments = @current_vendor.shipments.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at desc')
  end

  def show
    @shipment = @current_vendor.shipments.visible.find_by_id(params[:id])
  end

  def new
    @shipment = Shipment.new
    @shipment.vendor = @current_vendor
    @shipment.company = @current_company
    @shipment.receiver_id = @current_vendor.id
    @shipment.receiver_type = 'Vendor'
    @shipment_types = @current_vendor.shipment_types.visible.order(:name)
    @shipment_items = []
  end

  def edit
    @shipment = @current_vendor.shipments.visible.find_by_id(params[:id])
    @shipment_items = @shipment.shipment_items.visible
    @shipment_types = @current_vendor.shipment_types.visible.order(:name)
  end

  def create
    @shipment = Shipment.new(params[:shipment])
    @shipment.vendor = @current_vendor
    @shipment.company = @current_company
    @shipment.currency = @current_vendor.currency
    @shipment.total_cents = 0
    @shipment.purchase_price_total_cents = 0
    if @shipment.save
      @shipment.shipment_items.update_all :vendor_id => @shipment.vendor_id,
          :company_id => @shipment.company_id,
          :currency => @current_vendor.currency
      @shipment_items = @shipment.shipment_items.visible
      redirect_to edit_shipment_path(@shipment)
    else
      @shipment_types = @current_vendor.shipment_types.visible.order(:name)
      @shipment_items = @shipment.shipment_items.visible
      render :new
    end
  end

  def update
    @shipment = @current_vendor.shipments.visible.find_by_id(params[:id])
    if @shipment.update_attributes(params[:shipment])
      @shipment.shipment_items.update_all :vendor_id => @shipment.vendor_id, :company_id => @shipment.company_id
      redirect_to edit_shipment_path(@shipment)
    else
      @shipment_types = @current_vendor.shipment_types.visible.order(:name)
      render :edit
    end
  end

  def destroy
    @shipment = @current_vendor.shipments.visible.find_by_id(params[:id])
    @shipment.hide(@current_user)
    redirect_to shipments_path
  end
  
  #ajax
  def add_item
    @shipment = @current_vendor.shipments.visible.find_by_id(params[:shipment_id])
    @shipment_item = @shipment.add_shipment_item(params)
    @shipment_items = []
    
    @shipment_items << @shipment_item
    render :update_pos_display
  end
  
  #ajax
  def move_all_items_into_stock
    @shipment = @current_vendor.shipments.visible.find_by_id(params[:shipment_id])
    @shipment.move_all_items_into_stock
    render :nothing => true
  end
  
  #ajax
  def move_item_into_stock
    @shipment_item = @current_vendor.shipment_items.visible.find_by_id(params[:shipment_item_id])
    @shipment_item.move_into_stock(params[:quantity], params[:locationstring])
    render :nothing => true
  end
end
