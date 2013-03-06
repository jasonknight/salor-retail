class InvoiceBlurbsController < ApplicationController
  # GET /invoice_blurbs
  # GET /invoice_blurbs.json
  before_filter :authify, :initialize_instance_variables, :crumble
  before_filter :check_role, :except => [:crumble]

  def index
    @invoice_blurbs = $Vendor.invoice_blurbs.page(params[:page]).per(25)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @invoice_blurbs }
    end
  end

  # GET /invoice_blurbs/1
  # GET /invoice_blurbs/1.json
  def show
    @invoice_blurb = InvoiceBlurb.where(:vendor_id => $User.vendor_id).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @invoice_blurb }
    end
  end

  # GET /invoice_blurbs/new
  # GET /invoice_blurbs/new.json
  def new
    @invoice_blurb = InvoiceBlurb.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @invoice_blurb }
    end
  end

  # GET /invoice_blurbs/1/edit
  def edit
    @invoice_blurb = InvoiceBlurb.where(:vendor_id => $User.vendor_id).find(params[:id])
  end

  # POST /invoice_blurbs
  # POST /invoice_blurbs.json
  def create
    @invoice_blurb = InvoiceBlurb.new(params[:invoice_blurb])
    @invoice_blurb.vendor_id = $User.vendor_id
    respond_to do |format|
      if @invoice_blurb.save
        format.html { redirect_to :action => :index, notice: 'Invoice blurb was successfully created.' }
        format.json { render json: @invoice_blurb, status: :created, location: @invoice_blurb }
      else
        format.html { render action: "new" }
        format.json { render json: @invoice_blurb.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /invoice_blurbs/1
  # PUT /invoice_blurbs/1.json
  def update
    @invoice_blurb = InvoiceBlurb.where(:vendor_id => $User.vendor_id).find(params[:id])
    @invoice_blurb.vendor_id = $User.vendor_id
    respond_to do |format|
      if @invoice_blurb.update_attributes(params[:invoice_blurb])
        format.html { redirect_to :action => :index, notice: 'Invoice blurb was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @invoice_blurb.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invoice_blurbs/1
  # DELETE /invoice_blurbs/1.json
  def destroy
    @invoice_blurb = InvoiceBlurb.where(:vendor_id => $User.vendor_id).find(params[:id])
    @invoice_blurb.destroy

    respond_to do |format|
      format.html { redirect_to invoice_blurbs_url }
      format.json { head :no_content }
    end
  end
  private 
  
  def crumble
    @vendor = $User.get_vendor($User.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.invoice_blurbs"),'invoice_blurbs_path(:vendor_id => params[:vendor_id])'
  end
end
