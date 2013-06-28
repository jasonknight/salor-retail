# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ReportsController < ApplicationController
   before_filter :check_role, :only => [:new_pos, :index, :show, :new, :edit, :create, :update, :destroy]
   before_filter :crumble, :only => :selector

  def selector
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    if params[:commit]
      Report.new.dump_all(@from,@to)
      send_file File.join('/', 'tmp', 'salor-retail.zip')
      flash[:notice] = "Complete"
    end
  end

  def cash_account
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    @orders = Order.find(:all, :conditions => { :created_at => @from..@to, :paid => true })
    @orders.reverse!
    @taxes = TaxProfile.where( :hidden => 0)
  end

  def daily
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    @orders = Order.find(:all, :conditions => { :created_at => @from..@to, :paid => true })
    @orders.reverse!
    @taxes = TaxProfile.where( :hidden => 0)
  end

  private
  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id) if @vendor.nil?
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.report"),'reports_path(:vendor_id => params[:vendor_id])'
  end

end
