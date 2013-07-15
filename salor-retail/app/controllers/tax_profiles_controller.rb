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
    @tax_profile = @current_vendor.tax_profiles.find_by_id(params[:id])
    redirect_to edit_tax_profile_path(@tax_profile)
  end

  def new
    @tax_profile = TaxProfile.new
  end

  def edit
    @tax_profile = @current_vendor.tax_profiles.find_by_id(params[:id])
  end

  def create
    @tax_profile = TaxProfile.new(params[:tax_profile])
    @tax_profile.vendor = @current_vendor
    @tax_profile.company = @current_company

    if @tax_profile.save
      redirect_to tax_profiles_path
    else
      render :new
    end
  end

  def update
    @tax_profile = @current_vendor.tax_profiles.find_by_id(params[:id])
    if @tax_profile.update_attributes(params[:tax_profile])
      redirect_to tax_profiles_path
    else
      render :edit
    end
  end

  def destroy
    tp = @current_vendor.tax_profiles.find_by_id(params[:id])
    tp.hide(@current_user)
    redirect_to tax_profiles_path
  end
end
