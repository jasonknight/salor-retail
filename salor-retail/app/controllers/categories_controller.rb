# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software

class CategoriesController < ApplicationController
  before_filter :check_role
  
  def index
    @categories = @current_vendor.categories.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end

  def show
    @category = @current_vendor.categories.visible.find_by_id(params[:id])
  end

  def new
    @category = Category.new
  end

  def edit
    @category = @current_vendor.categories.visible.find_by_id(params[:id])
  end

  def create
    @category = Category.new(params[:category])
    @category.vendor = @current_vendor
    @category.company = @current_company
    if @category.save
      redirect_to categories_path
    else
      render :new
    end
  end

  def update
    @category = @current_vendor.categories.visible.find_by_id(params[:id])
    if @category.update_attributes(params[:category])
      redirect_to categories_path
    else
      render :edit
    end
  end
  
  def categories_json
    @categories = Category.scopied.page(params[:page]).per($Conf.pagination)
    render :text => @categories.to_json
  end
  
#   def items_json
#     @items = Item.scopied.find_by_category_id(params[:id].to_s).page(params[:page]).per($Conf.pagination)
#     render :text => @items.to_json
#   end

  def destroy
    @category = @current_vendor.categories.visible.find_by_id(params[:id])
    @category.hide(@current_user)
    redirect_to categories_path
  end


#   def get_tags
#     @tags = TransactionTag.scopied.all.unshift(TransactionTag.new(:name => ''))
#   end
end
