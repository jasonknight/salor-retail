# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ButtonsController < ApplicationController
  before_filter :check_role
  before_filter :get_button_categories

  def index
  end

  def show
    @button = @current_vendor.buttons.visible.find_by_id(params[:id])
    redirect_to button_path(@button)
  end

  def new
    @button = Button.new(params[:item])
  end

  def edit
    @button = @current_vendor.buttons.visible.find_by_id(params[:id])
  end

  def create
    @button = Button.new(params[:button])
    @button.vendor = @current_vendor
    @button.company = @current_company
    if @button.save
      redirect_to buttons_path
    else
      render :new
    end
  end

  def update
    @button = @current_vendor.buttons.visible.find_by_id(params[:id])
    if @button.update_attributes params[:button]
      redirect_to buttons_path
    else
      render :edit
    end
  end

  def destroy
    @button = @current_vendor.buttons.visible.find_by_id(params[:id])
    @button.hide(@current_user)
    redirect_to buttons_path
  end

  def position
    @buttons = @current_vendor.buttons.visible.where("id IN (#{params[:button].join(',')})")
    Button.sort(@buttons, params[:button])
    render :nothing => true
  end
  
  private
  
  def get_button_categories
    @button_categories = @current_vendor.categories.visible.where(:button_category => true).order(:position)
  end
end
