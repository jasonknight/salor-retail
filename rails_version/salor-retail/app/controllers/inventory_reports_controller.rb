class InventoryReportsController < ApplicationController
  

  def index
    @inventory_reports = @current_vendor.inventory_reports.visible.page(params[:page]).per(@current_vendor.pagination).order('created_at DESC')
  end
  
  def current
    @items = @current_vendor.items.visible.where(:real_quantity_updated => true)
    @category_ids = @items.select("DISTINCT category_id").collect{ |res| res.category_id }
    @category_ids << nil
    @category_ids.uniq!
    render :show
  end
  
  def show
    @inventory_report = @current_vendor.inventory_reports.find_by_id(params[:id])
    @items = @inventory_report.inventory_report_items
    @category_ids = @items.select("DISTINCT category_id").collect{ |res| res.category_id }
    @category_ids << nil
    @category_ids.uniq!
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
  
  
  def update_real_quantity
    @item = @current_vendor.items.visible.find_by_sku(params[:sku])
    @item.real_quantity = @item.real_quantity.to_f + params[:real_quantity].gsub(",",".").to_f
    @item.real_quantity ||= 0 # protect against errenous JS requests with missing 'real_quantity' param
    @item.real_quantity_updated = true
    result = @item.save
    if result != true
      raise "Could not save Item because #{ @item.errors.messages }"
    end
    render :json => {:status => 'success'}
  end
  
  def inventory_json
    @item = @current_vendor.items.visible.find_by_sku(params[:sku], :select => "name,sku,id,quantity,real_quantity")
    render :json => @item.to_json
  end
  
  def create_inventory_report
    @current_vendor.create_inventory_report
    redirect_to inventory_reports_path
  end
  
  
end
