# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class BrokenItemsController < ApplicationController
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /broken_items
  # GET /broken_items.xml
  def index
    @broken_items = BrokenItem.scopied.page(params[:page]).per(25)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @broken_items }
    end
  end

  # GET /broken_items/1
  # GET /broken_items/1.xml
  def show
    @broken_item = BrokenItem.scopied.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @broken_item }
    end
  end

  # GET /broken_items/new
  # GET /broken_items/new.xml
  def new
    @broken_item = BrokenItem.new
    @broken_item.name = params[:name]
    @broken_item.sku = params[:sku]
    @broken_item.base_price = params[:base_price]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @broken_item }
    end
  end

  # GET /broken_items/1/edit
  def edit
    @broken_item = BrokenItem.find(params[:id])
  end

  # POST /broken_items
  # POST /broken_items.xml
  def create
    @broken_item = BrokenItem.new(params[:broken_item])
    @broken_item.set_model_user
    respond_to do |format|
      if @broken_item.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => BrokenItem.model_name.human)) }
        format.xml  { render :xml => @broken_item, :status => :created, :location => @broken_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @broken_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /broken_items/1
  # PUT /broken_items/1.xml
  def update
    @broken_item = BrokenItem.scopied.find(params[:id])

    respond_to do |format|
      if @broken_item.update_attributes(params[:broken_item])
        format.html { redirect_to(:action => 'index', :notice => I18n.t("views.notice.model_edit", :model => BrokenItem.model_name.human)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @broken_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /broken_items/1
  # DELETE /broken_items/1.xml
  def destroy
    @broken_item = BrokenItem.scopied.find(params[:id])
    @broken_item.destroy

    respond_to do |format|
      format.html { redirect_to(broken_items_url) }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.broken_items"),'broken_items_path(:vendor_id => params[:vendor_id])'
  end
end
