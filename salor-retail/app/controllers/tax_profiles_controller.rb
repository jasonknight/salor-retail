# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class TaxProfilesController < ApplicationController
   before_filter :authify
   before_filter :initialize_instance_variables
   before_filter :check_role, :except => [:crumble]
   before_filter :crumble
   
  # GET /tax_profiles
  # GET /tax_profiles.xml
  def index
    @tax_profiles = $Vendor.tax_profiles.page(params[:page]).per(25)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tax_profiles }
    end
  end

  # GET /tax_profiles/1
  # GET /tax_profiles/1.xml
  def show
    @tax_profile = salor_user.get_tax_profile(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tax_profile }
    end
  end

  # GET /tax_profiles/new
  # GET /tax_profiles/new.xml
  def new
    @tax_profile = TaxProfile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tax_profile }
    end
  end

  # GET /tax_profiles/1/edit
  def edit
    @tax_profile = salor_user.get_tax_profile(params[:id])
    add_breadcrumb @tax_profile.name,'edit_tax_profile_path(@tax_profile)'
  end

  # POST /tax_profiles
  # POST /tax_profiles.xml
  def create
    @tax_profile = TaxProfile.new(params[:tax_profile])

    respond_to do |format|
      if @tax_profile.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => TaxProfile.model_name.human)) }
        format.xml  { render :xml => @tax_profile, :status => :created, :location => @tax_profile }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tax_profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tax_profiles/1
  # PUT /tax_profiles/1.xml
  def update
    @tax_profile = salor_user.get_tax_profile(params[:id])
    
    respond_to do |format|
      if @tax_profile.update_attributes(params[:tax_profile]) and not @tax_profile.order_items.any?
        format.html { render :action => 'edit', :notice => I18n.t("views.notice.model_edit", :model => TaxProfile.model_name.human) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit",:notice => I18n.t("system.errors.no_longer_editable", :model => TaxProfile.model_name.human) }
        format.xml  { render :xml => @tax_profile.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tax_profiles/1
  # DELETE /tax_profiles/1.xml
  def destroy
    @tax_profile = salor_user.get_tax_profile(params[:id])
    @tax_profile.kill

    respond_to do |format|
      format.html { redirect_to(tax_profiles_url) }
      format.xml  { head :ok }
    end
  end
  private
  def crumble
    add_breadcrumb I18n.t("menu.tax_profiles"),'tax_profiles_path()'
  end
end
