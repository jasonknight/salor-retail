# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ReportsController < ApplicationController
   before_filter :authify
   before_filter :initialize_instance_variables
   before_filter :check_role, :only => [:new_pos, :index, :show, :new, :edit, :create, :update, :destroy]
   before_filter :crumble, :only => :selector

  def selector
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    if not params[:usb_device].empty? and File.exists? params[:usb_device] then
      @report = Report.new
      @report.dump_all(@from,@to,params[:usb_device])
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
    @vendor = salor_user.get_vendor(salor_user.meta.vendor_id) if @vendor.nil?
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.report"),'reports_path(:vendor_id => params[:vendor_id])'
  end

end
