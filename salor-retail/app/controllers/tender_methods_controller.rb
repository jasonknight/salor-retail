# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class TenderMethodsController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /tender_methods
  # GET /tender_methods.xml
  def index
    @tender_methods = TenderMethod.scopied.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tender_methods }
    end
  end

  # GET /tender_methods/1
  # GET /tender_methods/1.xml
  def show
    @tender_method = TenderMethod.scopied.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tender_method }
    end
  end

  # GET /tender_methods/new
  # GET /tender_methods/new.xml
  def new
    @tender_method = TenderMethod.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tender_method }
    end
  end

  # GET /tender_methods/1/edit
  def edit
    @tender_method = TenderMethod.scopied.find(params[:id])
  end

  # POST /tender_methods
  # POST /tender_methods.xml
  def create
    @tender_method = TenderMethod.new(params[:tender_method])
    @tender_method.set_model_owner
    respond_to do |format|
      if @tender_method.save
        format.html { redirect_to(tender_methods_url, :notice => 'Tender method was successfully created.') }
        format.xml  { render :xml => @tender_method, :status => :created, :location => @tender_method }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tender_method.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tender_methods/1
  # PUT /tender_methods/1.xml
  def update
    @tender_method = TenderMethod.scopied.find(params[:id])

    respond_to do |format|
      if @tender_method.update_attributes(params[:tender_method])
        format.html { redirect_to(tender_methods_url, :notice => 'Tender method was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tender_method.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tender_methods/1
  # DELETE /tender_methods/1.xml
  def destroy
    @tender_method = TenderMethod.scopied.find(params[:id])
    @tender_method.kill

    respond_to do |format|
      format.html { redirect_to(tender_methods_url) }
      format.xml  { head :ok }
    end
  end
  private
  def crumble
    @vendor = GlobalData.salor_user.get_vendor(GlobalData.salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.tender_methods"),'tender_methods_path(:vendor_id => params[:vendor_id])'
  end
end
