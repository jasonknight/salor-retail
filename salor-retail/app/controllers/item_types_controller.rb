# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ItemTypesController < ApplicationController
  # GET /item_types
  # GET /item_types.xml
  before_filter :crumble

  def index
    @item_types = ItemType.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @item_types }
    end
  end

  # GET /item_types/1
  # GET /item_types/1.xml
  def show
    @item_type = ItemType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item_type }
    end
  end

  # GET /item_types/new
  # GET /item_types/new.xml
  def new
    @item_type = ItemType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @item_type }
    end
  end

  # GET /item_types/1/edit
  def edit
    @item_type = ItemType.find(params[:id])
    add_breadcrumb @item_type.name,'edit_item_type_path(@item_type,:vendor_id => params[:vendor_id])'
  end

  # POST /item_types
  # POST /item_types.xml
  def create
    @item_type = ItemType.new(params[:item_type])

    respond_to do |format|
      if @item_type.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => ItemType.model_name.human)) }
        format.xml  { render :xml => @item_type, :status => :created, :location => @item_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /item_types/1
  # PUT /item_types/1.xml
  def update
    @item_type = ItemType.find(params[:id])

    respond_to do |format|
      if @item_type.update_attributes(params[:item_type])
        format.html { render :action => 'edit', :notice => 'Item type was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /item_types/1
  # DELETE /item_types/1.xml
  def destroy
    @item_type = ItemType.find(params[:id])
    # You cannot destroy item types
    respond_to do |format|
      format.html { redirect_to(item_types_url) }
      format.xml  { head :ok }
    end
  end
  def crumble
    add_breadcrumb I18n.t("menu.item_types"),'item_types_path(:vendor_id => params[:vendor_id])'
  end
end
