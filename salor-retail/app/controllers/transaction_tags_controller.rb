# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class TransactionTagsController < ApplicationController
  before_filter :check_role

  def index
    @transaction_tags = @current_vendor.transaction_tags.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end

  def show
    @transaction_tag = @current_vendor.transaction_tags.visible.find_by_id(params[:id])
    redirect_to edit_transaction_tag_path(@transaction_tag)
  end

  def new
    @transaction_tag = TransactionTag.new
  end

  def edit
    @transaction_tag = @current_vendor.transaction_tags.visible.find_by_id(params[:id])
  end

  def create
    @transaction_tag = TransactionTag.new(params[:transaction_tag])
    @transaction_tag.vendor = @current_vendor
    @transaction_tag.company = @current_company
    if @transaction_tag.save
      redirect_to transaction_tags_path
    else
      render :new
    end
  end

  def update
    @transaction_tag = @current_vendor.transaction_tags.visible.find_by_id(params[:id])
    if @transaction_tag.update_attributes(params[:transaction_tag])
      redirect_to transaction_tags_path
    else
      render :edit
    end
  end

  def destroy
    @transaction_tag = @current_vendor.transaction_tags.visible.find_by_id(params[:id])
    @transaction_tag.hide(@current_user)
    redirect_to transaction_tags_path
  end
end
