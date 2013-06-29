class SaleTypesController < ApplicationController
  
  def index
    @sale_types = SaleType.scopied.page(params[:page]).per(25)
  end
  
  def new
    @sale_type = SaleType.new
  end
  
  def create
    @sale_type = SaleType.new(params[:sale_type])
    @sale_type.set_model_user
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
    redirect_to sale_types_path and return unless @sale_type
    render :new
  end
  
  def destroy
    @sale_type = SaleType.find_by_id(params[:id])
    redirect_to roles_path and return unless @sale_type
    @sale_type.update_attribute :hidden, true
    redirect_to sale_types_path
  end
  private
  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("activerecord.models.sale_type.other"),'invoice_notes_path(:vendor_id => params[:vendor_id])'
  end
end
