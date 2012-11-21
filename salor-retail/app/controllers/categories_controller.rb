# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class CategoriesController < ApplicationController
  # {START}
  before_filter :authify, :initialize_instance_variables, :crumble, :get_tags
  before_filter :check_role, :except => [:crumble]
  cache_sweeper :category_sweeper, :only => [:create, :update, :destroy]
  
  def index
    @categories = $User.get_categories(params[:page])
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  def show
    @category = Category.by_vendor.visible.find_by_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

  def new
    @category = Category.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  def edit
    @category = $User.get_category(params[:id])
    add_breadcrumb @category.name,'edit_category_path(@category)'
  end

  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        GlobalData.reload(:categories)
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Category.model_name.human)) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @category = $User.get_category(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        GlobalData.reload(:categories)
        format.html { render :action => 'edit', :notice => I18n.t("views.notice.model_edit", :model => Category.model_name.human) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end
  def categories_json
    @categories = Category.scopie.page(params[:page]).per(params[:per_page])
    render :text => @categories.to_json
  end
  def items_json
    @items = Item.scopied.find_by_category_id(params[:id]).page(params[:page]).per(params[:per_page])
    render :text => @items.to_json
  end

  def destroy
    @category = GlobalData.salor_user.get_category(params[:id])
    @category.kill
    GlobalData.reload(:categories)
    respond_to do |format|
      format.html { redirect_to(categories_url) }
      format.xml  { head :ok }
    end
  end

  private 

  def crumble
    @vendor = GlobalData.salor_user.get_vendor(GlobalData.salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.categories"),'categories_path(:vendor_id => params[:vendor_id])'
  end

  def get_tags
    @tags = TransactionTag.scopied.all.unshift(TransactionTag.new(:name => ''))
  end
  # {END}
end
