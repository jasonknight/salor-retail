# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class TransactionTagsController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /transaction_tags
  # GET /transaction_tags.xml
  def index
    @transaction_tags = TransactionTag.scopied.page(params[:page]).per(25)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transaction_tags }
    end
  end

  # GET /transaction_tags/1
  # GET /transaction_tags/1.xml
  def show
    @transaction_tag = TransactionTag.scopied.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @transaction_tag }
    end
  end

  # GET /transaction_tags/new
  # GET /transaction_tags/new.xml
  def new
    @transaction_tag = TransactionTag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transaction_tag }
    end
  end

  # GET /transaction_tags/1/edit
  def edit
    @transaction_tag = TransactionTag.scopied.find(params[:id])
  end

  # POST /transaction_tags
  # POST /transaction_tags.xml
  def create
    @transaction_tag = TransactionTag.new(params[:transaction_tag])

    respond_to do |format|
      if @transaction_tag.save
        atomize(ISDIR, 'cash_drop')
        format.html { redirect_to(:action => "new", :notice => 'Transaction tag was successfully created.') }
        format.xml  { render :xml => @transaction_tag, :status => :created, :location => @transaction_tag }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transaction_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /transaction_tags/1
  # PUT /transaction_tags/1.xml
  def update
    @transaction_tag = TransactionTag.scopied.find(params[:id])

    respond_to do |format|
      if @transaction_tag.update_attributes(params[:transaction_tag])
        atomize(ISDIR, 'cash_drop')
        format.html { redirect_to(:action => 'index', :notice => 'Transaction tag was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @transaction_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /transaction_tags/1
  # DELETE /transaction_tags/1.xml
  def destroy
    @transaction_tag = TransactionTag.scopied.find(params[:id])
    @transaction_tag.kill
    atomize(ISDIR, 'cash_drop')
    respond_to do |format|
      format.html { redirect_to(transaction_tags_url) }
      format.xml  { head :ok }
    end
  end

  def logo
    @transaction_tag = TransactionTag.scopied.find(params[:id])
    send_data @transaction_tag.logo_image, :type => @transaction_tag.logo_image_content_type, :disposition => 'inline'
  end

  private 
  def crumble
    @vendor = GlobalData.salor_user.get_vendor(GlobalData.salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.transaction_tags"),'transaction_tags_path(:vendor_id => params[:vendor_id])'
  end
end
