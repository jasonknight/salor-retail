class InvoiceBlurbsController < ApplicationController

  before_filter :check_role

  def index
    @invoice_blurbs = @current_vendor.invoice_blurbs.visible.page(params[:page]).per(@current_vendor.pagination)
  end

  def show
    @invoice_blurb = @current_vendor.invoice_blurbs.visible.find_by_id(params[:id])
    redirect_to edit_invoice_blurb_path(@invoice_blurb)
  end

  def new
    @invoice_blurb = InvoiceBlurb.new
  end

  def edit
    @invoice_blurb = @current_vendor.invoice_blurbs.visible.find_by_id(params[:id])
  end

  def create
    @invoice_blurb = InvoiceBlurb.new(params[:invoice_blurb])
    @invoice_blurb.vendor = @current_vendor
    @invoice_blurb.company = @current_company
    if @invoice_blurb.save
      redirect_to invoice_blurbs_path
    else
      render :new
    end
  end

  def update
    @invoice_blurb = @current_vendor.invoice_blurbs.visible.find_by_id(params[:id])
    if @invoice_blurb.update_attributes(params[:invoice_blurb])
      redirect_to invoice_blurbs_path
    else
      render :edit
    end
  end

  def destroy
    @invoice_blurb = @current_vendor.invoice_blurbs.visible.find_by_id(params[:id])
    @invoice_blurb.hide(@current_user)
    redirect_to invoice_blurbs_path
  end
end
