# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ActionsController < ApplicationController
  before_filter :check_role

  def index
    if params[:keywords].blank?
      @actions = @current_vendor.actions.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
    else
      items = @current_vendor.items.visible.by_keywords(params[:keywords])
      @actions = []
      items.each { |i| @actions += i.actions.visible }
    end
  end

  def show
    @action = @current_vendor.actions.visible.find_by_id(params[:id])
    redirect_to edit_action_path(@action)
  end

  def new
    @action = Action.new
    @action.vendor = @current_vendor
  end

  def edit
    @action = @current_vendor.actions.visible.find_by_id(params[:id])
  end

  def create
    @action = Action.new
    @action.vendor = @current_vendor
    @action.company = @current_company
    @action.created_by = @current_user.id
    @action.update_attributes(params[:act])
    if @action.save
      redirect_to actions_path
    else
      render :new
    end
  end

  def update
    @action = @current_vendor.actions.visible.find_by_id(params[:id])
    @action.created_by = @current_user.id if @action.created_by.nil?
    if @action.update_attributes(params[:act])
      redirect_to actions_path
    else
      render :edit
    end
  end

  def destroy
    @action = @current_vendor.actions.visible.find_by_id(params[:id])
    @action.hide(@current_user)
    redirect_to actions_path
  end
end
