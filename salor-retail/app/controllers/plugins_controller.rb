# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class PluginsController < ApplicationController
  before_filter :check_role

  def index
    @plugins = @current_vendor.plugins.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end

  def show
    @plugin = @current_vendor.plugins.visible.find_by_id(params[:id])
    redirect_to edit_plugin_path(@plugin)
  end

  def new
    @plugin = Plugin.new
    @plugin.vendor = @current_vendor
    @plugin.company = @current_company
  end

  def edit
    @plugin = @current_vendor.plugins.visible.find_by_id(params[:id])
  end

  def create
    @plugin = Plugin.new
    @plugin.vendor = @current_vendor
    @plugin.company = @current_company
    @plugin.save
    
    @plugin.filename = params[:plugin][:filename]

    if @plugin.save
      @plugin.unzip
      redirect_to plugins_path
    else
      render :new
    end
  end

  def update
    @plugin = @current_vendor.plugins.visible.find_by_id(params[:id])
    if @plugin.update_attributes(params[:plugin])
      #@plugin.unzip # I disabled this because it was overriding my development changes in the uploads dir
      redirect_to plugins_path
    else
      render :edit
    end
  end

  def destroy
    @plugin = @current_vendor.plugins.visible.find_by_id(params[:id])
    @plugin.hide(@current_user)
    redirect_to plugins_path
  end
end
