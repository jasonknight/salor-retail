# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class BrokenItemsController < ApplicationController
  before_filter :check_role

  def index
    @broken_items = @current_vendor.broken_items.visible.order("created_at DESC").by_keywords(params[:keywords]).page(params[:page]).per(@current_vendor.pagination)
  end

  def show
    i = @current_vendor.broken_items.visible.find_by_id(params[:id])
    redirect_to edit_broken_item_path(i)
  end

  def new
    @item = BrokenItem.new
    @item.vendor = @current_vendor
    @item.company = @current_company
    @item.name = params[:name]
    @item.sku = params[:sku]
    @item.price = params[:base_price]
  end

  def edit
    @item = @current_vendor.broken_items.visible.find_by_id(params[:id])
  end

  def create
    @item = BrokenItem.new(params[:broken_item])
    @item.vendor = @current_vendor
    @item.company = @current_company
    @item.currency = @current_vendor.currency
    if @item.save
      redirect_to broken_items_path
    else
      render :new
    end
  end

  def update
    @item = @current_vendor.broken_items.visible.find_by_id(params[:id])
    if @item.update_attributes(params[:broken_item])
      redirect_to broken_items_path
    else
      render :edit
    end
  end

  def destroy
    @item = @current_vendor.broken_items.visible.find_by_id(params[:id])
    @item.hide(@current_user)
    redirect_to broken_items_path
  end
end
