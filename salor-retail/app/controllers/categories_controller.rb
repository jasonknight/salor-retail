# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class CategoriesController < ApplicationController
  # {START}
  before_filter :authify, :initialize_instance_variables, :crumble, :get_tags
  before_filter :check_role, :except => [:crumble]
  
  def index
    @categories = $Vendor.categories.scopied.page(params[:page]).per($Conf.pagination)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  def show
    @category = Category.by_vendor.visible.find_by_id(params[:id].to_s)

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
    @category = $Vendor.categories.find_by_id(params[:id].to_s)
    add_breadcrumb @category.name,'edit_category_path(@category)'
  end

  def create
    @category = Category.new(params[:category])
    @category.set_model_owner($User)
    respond_to do |format|
      if @category.save
        
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Category.model_name.human)) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @category = $Vendor.categories.find_by_id(params[:id].to_s)

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
    @categories = Category.scopied.page(params[:page]).per($Conf.pagination)
    render :text => @categories.to_json
  end
  def items_json
    @items = Item.scopied.find_by_category_id(params[:id].to_s).page(params[:page]).per($Conf.pagination)
    render :text => @items.to_json
  end

  def destroy
    @category = $Vendor.categories.find_by_id(params[:id].to_s)
    @category.kill
    GlobalData.reload(:categories)
    respond_to do |format|
      format.html { redirect_to(categories_url) }
      format.xml  { head :ok }
    end
  end

  private 

  def crumble
    @vendor = $Vendor
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.categories"),'categories_path(:vendor_id => params[:vendor_id])'
  end

  def get_tags
    @tags = TransactionTag.scopied.all.unshift(TransactionTag.new(:name => ''))
  end
  # {END}
end
