# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ReportsController < ApplicationController
  
  def index
    redirect_to '/' and return if @current_company.mode != 'local'
    
    @locations = Dir['/media/*']
    @locations << Dir['/home/*']
    @locations.flatten!
    @from, @to = assign_from_to(params)
    @models_for_csv = [OrderItem]
    
    if params.has_key?(:fisc_save)
      zip_outfile = @current_vendor.fisc_dump(@from, @to, params[:location])
      redirect_to reports_path
      return
    elsif params.has_key?(:fisc_download)
      zip_outfile = @current_vendor.fisc_dump(@from, @to, '/tmp')
      send_file zip_outfile
    elsif params.has_key?(:csv_download)
      csv_outfile = @current_vendor.csv_dump(params[:csv_type], @from, @to)
      send_data csv_outfile, :filename => "#{ params[:csv_type] }.csv" if csv_outfile
    end
  end

# 
#   def cash_account
#     @from, @to = assign_from_to(params)
#     @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
#     @to = @to ? @to.end_of_day : @from.end_of_day
#     @orders = Order.find(:all, :conditions => { :created_at => @from..@to, :paid => true })
#     @orders.reverse!
#     @taxes = TaxProfile.where( :hidden => 0)
#   end
# 
#   def daily
#     @from, @to = assign_from_to(params)
#     @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
#     @to = @to ? @to.end_of_day : @from.end_of_day
#     @orders = Order.find(:all, :conditions => { :created_at => @from..@to, :paid => true })
#     @orders.reverse!
#     @taxes = TaxProfile.where( :hidden => 0)
#   end

end
