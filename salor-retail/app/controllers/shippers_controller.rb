# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ShippersController < ApplicationController
  # GET /shippers
  # GET /shippers.xml
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  cache_sweeper :shipper_sweeper, :only => [:create, :update, :destroy]

  def index
    @shippers = Shipper.where(:vendor_id => $User.vendor_id).order("id asc").page(params[:page]).per(25)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @shippers }
    end
  end

  # GET /shippers/1
  # GET /shippers/1.xml
  def show
    @shipper = Shipper.find(params[:id])
    add_breadcrumb @shipper.name,'shipper_path(@shipper)'
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @shipper }
    end
  end

  # GET /shippers/new
  # GET /shippers/new.xml
  def new
    @shipper = Shipper.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @shipper }
    end
  end

  # GET /shippers/1/edit
  def edit
    @shipper = Shipper.find(params[:id])
    add_breadcrumb @shipper.name,'edit_shipper_path(@shipper)'
  end

  # POST /shippers
  # POST /shippers.xml
  def create
    @shipper = Shipper.new(params[:shipper])

    respond_to do |format|
      if @shipper.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Shipper.model_name.human)) }
        format.xml  { render :xml => @shipper, :status => :created, :location => @shipper }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @shipper.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /shippers/1
  # PUT /shippers/1.xml
  def update
    @shipper = Shipper.find(params[:id])

    respond_to do |format|
      if @shipper.update_attributes(params[:shipper])
        format.html { redirect_to :action => 'index', :notice => 'Shipper was successfully updated.' and return }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @shipper.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /shippers/1
  # DELETE /shippers/1.xml
  def destroy
    @shipper = Shipper.find(params[:id])
    @shipper.kill

    respond_to do |format|
      format.html { redirect_to(shippers_url) }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    add_breadcrumb I18n.t("menu.vendors"),'vendors_path'
    add_breadcrumb @vendor.name,'vendor_path(@vendor)' if @vendor
    add_breadcrumb I18n.t("menu.shippers"),'shippers_path()'
  end
end
