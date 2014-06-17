# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ReportsController < ApplicationController
  
  def index
    if @current_company.mode != 'local'
      $MESSAGES[:alerts] << "This feature is not available in Demo mode"
      redirect_to '/' and return 
    end
    
    @locations = Dir['/media/*']
    @locations << Dir['/home/*']
    @locations.flatten!
    @from, @to = assign_from_to(params)
    @models_for_csv = [OrderItem, Item]
    
    
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

end
