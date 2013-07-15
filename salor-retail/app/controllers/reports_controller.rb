# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ReportsController < ApplicationController
   before_filter :check_role, :only => [:new_pos, :index, :show, :new, :edit, :create, :update, :destroy]

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

end
