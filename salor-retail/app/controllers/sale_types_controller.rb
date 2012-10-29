class SaleTypesController < ApplicationController
  
  def index
    @sale_types = SaleType.scopied
  end
  
  def new
    @sale_type = SaleType.new
  end
  
  def create
    @sale_type = SaleType.new(params[:sale_type])
    @sale_type.set_model_owner
    if @sale_type.save
      redirect_to sale_types_path
    else
      render :new
    end
  end
  
  def update
    @sale_type = SaleType.find_by_id(params[:id])
    if @sale_type.update_attributes(params[:sale_type])
      redirect_to sale_types_path
    else
      render :new
    end
  end
  
  def edit
    @sale_type = SaleType.find_by_id(params[:id])
    redirect_to sales_types_path and return unless @sale_type
    render :new
  end
  
  def destroy
    @sale_type = SaleType.find_by_id(params[:id])
    redirect_to roles_path and return unless @sale_type
    @sale_type.update_attribute :hidden, true
    redirect_to sales_types_path
  end
end
