class InvoiceNotesController < ApplicationController
  
  def index
    @invoice_notes = @current_vendor.invoice_notes.visible.page(params[:page]).per(@current_vendor.pagination)
  end
  
  def new
    @invoice_note = InvoiceNote.new
    @sale_types = @current_vendor.sale_types.visible
    @countries = @current_vendor.countries.visible
  end
  
  def create
    @invoice_note = InvoiceNote.new(params[:invoice_note])
    @invoice_note.vendor = @current_vendor
    @invoice_note.company = @current_company
    if @invoice_note.save
      redirect_to invoice_notes_path
    else
      @sale_types = @current_vendor.sale_types.visible
      @countries = @current_vendor.countries.visible
      render :new
    end
  end
  
  def update
    @invoice_note = @current_vendor.invoice_notes.visible.find_by_id(params[:id])
    if @invoice_note.update_attributes(params[:invoice_note])
      redirect_to invoice_notes_path
    else
      render :new
    end
  end
  
  def edit
    @invoice_note = @current_vendor.invoice_notes.visible.find_by_id(params[:id])
    @sale_types = @current_vendor.sale_types.visible
    @countries = @current_vendor.countries.visible
    redirect_to invoice_notes_path and return unless @invoice_note
    render :new
  end
  
  def destroy
    @invoice_note = @current_vendor.invoice_notes.visible.find_by_id(params[:id])
    @invoice_note.hide(@current_user)
    redirect_to invoice_notes_path
  end
end
