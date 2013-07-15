# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class DiscountsController < ApplicationController

  before_filter :check_role

  
  def index
    @discounts = @current_vendor.discounts.visible.order("created_at DESC").page(params[:page]).per(@current_vendor.pagination)
  end

  def show
    @discount = @current_vendor.discounts.visible.find_by_id(params[:id])
    redirect_to edit_discount_path(@discount)
  end

  def new
    @discount = @current_vendor.discounts.build
  end

  def edit
    @discount = @current_vendor.discounts.visible.find_by_id(params[:id])
  end

  def create
    @discount = Discount.new(params[:discount])
    @discount.vendor = @current_vendor
    @discount.company = @current_company
    if @discount.save
      redirect_to discounts_path
    else
      render :new
    end
  end

  def update
    @discount = @current_vendor.discounts.visible.find_by_id(params[:id])
    if @discount.update_attributes(params[:discount])
      redirect_to discounts_path
    else
      render :edit
    end
  end

  def destroy
    @discount = @current_vendor.discounts.visible.find_by_id(params[:id])
    @discount.hide(@current_user)
    redirect_to discounts_path
  end
end
