# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ActionsController < ApplicationController
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /actions
  # GET /actions.xml
  def index
    @actions = Action.scopied.order("id desc").page(params[:page]).per(25)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @actions }
    end
  end

  # GET /actions/1
  # GET /actions/1.xml
  def show
    @action = Action.scopied.find_by_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @action }
    end
  end

  # GET /actions/new
  # GET /actions/new.xml
  def new
    @action = Action.new(params[:item])
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @action }
    end
  end

  # GET /actions/1/edit
  def edit
    @action = Action.scopied.find_by_id(params[:id])
  end

  # POST /actions
  # POST /actions.xml
  def create
    @action = Action.find_by_id(params[:id])
    if not @action then
      @action = Action.new(params[:item])
    else
      @action.attributes  = params[:item]
    end
    @action.set_model_owner
    respond_to do |format|
      if @action.save
        format.html { redirect_to(:action => :index, :notice => 'Action was successfully created.') }
        format.xml  { render :xml => @action, :status => :created, :location => @action }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @action.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /actions/1
  # PUT /actions/1.xml
  def update
    @action = Action.scopied.find(params[:id])

    respond_to do |format|
      if @action.update_attributes(params[:item])
        format.html { redirect_to(:action => :index, :notice => 'Action was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @action.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /actions/1
  # DELETE /actions/1.xml
  def destroy
    @action = Action.scopied.find(params[:id])
    @action.destroy

    respond_to do |format|
      format.html { redirect_to(request.referer) }
      format.xml  { head :ok }
    end
  end
  private
  def crumble
    @vendor = @current_user.vendor(GlobalData.@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.actions"),'actions_path(:vendor_id => params[:vendor_id])'
  end
end
