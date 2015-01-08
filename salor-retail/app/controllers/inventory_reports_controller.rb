class InventoryReportsController < ApplicationController
  

  def index
    @inventory_reports = @current_vendor.inventory_reports.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end
  
  def current
    @items = @current_vendor.items.visible.where(:real_quantity_updated => true)
    @category_ids = @items.select("DISTINCT category_id").collect{ |res| res.category_id }
    @category_ids << nil
    render :show
  end
  
  def show
    @inventory_report = @current_vendor.inventory_reports.find_by_id(params[:id])
    @items = @inventory_report.inventory_report_items
    @category_ids = @items.select("DISTINCT category_id").collect{ |res| res.category_id }
    @category_ids << nil
  end
  
  def edit
    @inventory_report = @current_vendor.inventory_reports.find_by_id(params[:id])
    redirect_to inventory_report_path(@inventory_report)
  end
  
  def destroy
    @inventory_report = @current_vendor.inventory_reports.find_by_id(params[:id])
    @inventory_report.hide(@current_user.id)
    redirect_to inventory_reports_path
  end
  
  
end
