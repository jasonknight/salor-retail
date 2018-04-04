class SaleTypesController < ApplicationController
  
  def index
    @sale_types = @current_vendor.sale_types.visible.page(params[:page]).per(@current_vendor.pagination)
  end
  
  def new
    @sale_type = SaleType.new
  end
  
  def create
    @sale_type = SaleType.new(params[:sale_type])
    @sale_type.vendor = @current_vendor
    @sale_type.company = @current_company
    if @sale_type.save
      redirect_to sale_types_path
    else
      render :new
    end
  end
  
  def update
    @sale_type = @current_vendor.sale_types.visible.find_by_id(params[:id])
    if @sale_type.update_attributes(params[:sale_type])
      redirect_to sale_types_path
    else
      render :new
    end
  end
  
  def show
    @sale_type = @current_vendor.sale_types.visible.find_by_id(params[:id])
    redirect_to edit_sale_type_path(@sale_type)
  end
  
  def edit
    @sale_type = @current_vendor.sale_types.visible.find_by_id(params[:id])
    render :new
  end
  
  def destroy
    @sale_type = @current_vendor.sale_types.visible.find_by_id(params[:id])
    @sale_type.hide(@current_user)
    redirect_to sale_types_path
  end
end
