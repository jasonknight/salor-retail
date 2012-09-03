# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class DiscountsController < ApplicationController
  # {START}
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /discounts
  # GET /discounts.xml
  def index
    @discounts = salor_user.get_discounts

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @discounts }
    end
  end

  # GET /discounts/1
  # GET /discounts/1.xml
  def show
    @discount = salor_user.get_discount(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @discount }
    end
  end

  # GET /discounts/new
  # GET /discounts/new.xml
  def new
    @discount = Discount.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @discount }
    end
  end

  # GET /discounts/1/edit
  def edit
    @discount = salor_user.get_discount(params[:id])
  end

  # POST /discounts
  # POST /discounts.xml
  def create
    @discount = Discount.new(params[:discount])
    OrderItem.reload_discounts
    respond_to do |format|
      if @discount.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Discount.model_name.human)) }
        format.xml  { render :xml => @discount, :status => :created, :location => @discount }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @discount.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /discounts/1
  # PUT /discounts/1.xml
  def update
    @discount = salor_user.get_discount(params[:id])
    OrderItem.reload_discounts
    respond_to do |format|
      if @discount.update_attributes(params[:discount])
        format.html { render :action => 'edit', :notice => 'Discount was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @discount.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /discounts/1
  # DELETE /discounts/1.xml
  def destroy
    @discount = salor_user.get_discount(params[:id])
    if @discount then
      @discount.kill
    end

    respond_to do |format|
      format.html { redirect_to(discounts_url) }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = salor_user.get_vendor(salor_user.meta.vendor_id) if @vendor.nil?
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.discounts"),'discounts_path(:vendor_id => params[:vendor_id])'
  end
  # {END}
end
