# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ButtonsController < ApplicationController
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  
  def index
    @button_categories = Category.where(:button_category => true).order(:position)
  end
  #
  def show
    @button = Button.scopied.find(params[:id])
  end

  def new
    @button = Button.new(params[:item])
    @button_categories = Category.where(:button_category => true).order(:position)
  end

  def edit
    @button = Button.scopied.find_by_id(params[:id])
    @button_categories = Category.where(:button_category => true).order(:position)
  end

  def create
    @button = Button.new(params[:button])
    respond_to do |format|
      if @button.save
        format.html { redirect_to(buttons_url, :notice => 'Button was successfully created.') }
        format.xml  { render :xml => @button, :status => :created, :location => @button }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @button.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @button = Button.scopied.find_by_id(params[:id])

    @button.update_attributes params[:button]
    redirect_to buttons_path
  end

  def destroy
    @button = Button.scopied.find_by_id(params[:id])
  @button.kill if @button

    respond_to do |format|
      format.html { redirect_to(buttons_url) }
      format.xml  { head :ok }
    end
  end
  #
  def position
    @buttons = Button.scopied.where("id IN (#{params[:button].join(',')})")
    Button.sort(@buttons,params[:button])
    render :nothing => true
  end

  private 

  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.buttons"),'buttons_path(:vendor_id => params[:vendor_id])'
  end
end
