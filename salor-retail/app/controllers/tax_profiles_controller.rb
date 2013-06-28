# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class TaxProfilesController < ApplicationController
   before_filter :check_role
   

  def index
    @tax_profiles = @current_vendor.tax_profiles.visible.page(params[:page]).per(25)
  end

  def show
    @tax_profile = @current_vendor.tax_profiles.find(params[:id])
  end

  def new
    @tax_profile = TaxProfile.new
  end

  def edit
    @tax_profile = @current_vendor.tax_profiles.find(params[:id])
  end

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
    @tax_profile = @current_vendor.tax_profiles.find(params[:id].to_s)
    
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
    @tax_profile = @current_vendor.tax_profiles.find(params[:id].to_s)
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
