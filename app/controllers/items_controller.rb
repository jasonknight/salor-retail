# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
require 'rubygems'
require 'mechanize'
class ItemsController < ApplicationController
  # {START}
  before_filter :authify, :except => [:wholesaler_update, :labels]
  before_filter :initialize_instance_variables, :except => [:labels]
  before_filter :check_role, :except => [:info, :search, :labels, :crumble, :wholesaler_update]
  before_filter :crumble, :except => [:wholesaler_update, :labels]
  
  # GET /items
  # GET /items.xml
  def index
    if not check_license() then
      redirect_to :controller => "home", :action => "index" and return
    end
    if params[:order_by] then
      key = params[:order_by]
      session[key] = (session[key] == 'DESC') ? 'ASC' : 'DESC'
      @items = Item.scopied.page(params[:page]).per(25).order("#{key} #{session[key]}")
    else
      @items = Item.scopied.page(params[:page]).per(25)
    end
    Node.flush
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @items }
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    if not check_license() then
      redirect_to :controller => "home", :action => "index" and return
    end
    @item = salor_user.get_item(params[:id])
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : 1.month.ago.beginning_of_day
    @to = @to ? @to.end_of_day : DateTime.now
    @sold_times = OrderItem.scopied.find(:all, :conditions => {:sku => @item.sku, :hidden => 0, :is_buyback => false, :refunded => false, :created_at => @from..@to}).size
  end

  # GET /items/new
  # GET /items/new.xml
  def new
    @item = Item.new(:vendor_id => GlobalData.salor_user.meta.vendor_id)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.scopied.where(["id = ? or sku = ? or sku = ?",params[:id],params[:id],params[:keywords]]).first
    if not @item then
      redirect_to(:action => 'new', :notice => I18n.t("system.errors.item_not_found")) and return
    end
    add_breadcrumb @item.name,'edit_item_path(@item,:vendor_id => params[:vendor_id])'
   
  end

  # POST /items
  # POST /items.xml
  def create
    # We must insure that tax_profile is set first, otherwise, the
    # gross magic won't work
    # TODO Test this as it's no longer necessary
    @item = Item.all_seeing.find_by_sku(params[:item][:sku])
    if @item then
      @item.attributes = params[:item]
      flash[:notice] = I18n.t('system.errors.sku_must_be_unique',:sku => @item.sku)
      render :action => "new" and return
    end
    @item = Item.new
    @item.tax_profile_id = params[:item][:tax_profile_id]
    @item.attributes = params[:item]
    @item.sku.upcase!

    respond_to do |format|
      if salor_user.owns_vendor?(@item.vendor_id) and @item.save
        @item.set_model_owner(salor_user)
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Item.model_name.human)) }
        format.xml  { render :xml => @item, :status => :created, :location => @item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def create_ajax
    @item = Item.new()
    @item.tax_profile_id = params[:item][:tax_profile_id]
    @item.attributes = params[:item]
    respond_to do |format|
      if salor_user.owns_vendor?(@item.vendor_id) and @item.save
        @item.set_model_owner(salor_user)
        format.json  { render :json => @item }
      else
        format.json  { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = salor_user.get_item(params[:id])
    saved = false
    params[:item][:sku].upcase!
    if @item.nil? then
      # puts  "item was nil!"
      @item = Item.new(params[:item])
      if @item.save then
        saved = true
      end
    else
      # puts  "Updating Item #{params[:item][:price_by_qty].to_i}"
      if params[:item][:price_by_qty].to_i == 1 then
        params[:item][:price_by_qty] = true
        # puts  "Set to true"
      else
        params[:item][:price_by_qty] = false
      end
      @item.attributes = params[:item]
      if @item.save then
        saved = true
      end
    end
    respond_to do |format|
      if saved
        @item.set_model_owner(salor_user)
        format.html { redirect_to(:action => 'index', :notice => I18n.t("views.notice.model_edit", :model => Item.model_name.human)) }
        format.xml  { head :ok }
      else
        format.html { flash[:notice] = "There was an error!";render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end
  def update_real_quantity
    add_breadcrumb I18n.t("menu.update_real_quantity"), items_update_real_quantity_path
    if request.post? then
      @item = Item.scopied.find_by_sku(params[:sku])
      @item.update_attribute(:real_quantity, params[:quantity])
    end
  end
  def move_real_quantity
    Item.scopied.where("real_quantity > 0").each do |item|
      item.update_attribute(:quantity, item.real_quantity)
      item.update_attribute(:real_quantity, 0)
    end
    redirect_to items_update_real_quantity_path, :notice => t('views.notice.move_real_quantities_success')
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find_by_id(params[:id])
    if $User.owns_this?(@item) then
      if @item.order_items.any? then
        @item.update_attribute(:hidden,1)
        @item.update_attribute(:sku, rand(999).to_s + 'OLD:' + @item.sku)
      else
        @item.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to(items_url) }
      format.xml  { head :ok }
    end
  end
  
  def info
    if params[:sku] then
      @item = Item.find_by_sku(params[:sku])
    else
      @item = Item.find(params[:id]) if Item.exists? params[:id]
    end
  end
  #
  def report

  end
  #
  def search
    if not salor_user.owns_vendor? salor_user.meta.vendor_id then
      salor_user.meta.vendor_id = salor_user.get_default_vendor.id
    end
    @items = []
    @customers = []
    @orders = []
    if params[:klass] == 'Item' then
      @items = Item.scopied.page(params[:page]).per(GlobalData.conf.pagination)
    elsif params[:klass] == 'Order'
      if params[:keywords].empty? then
        @orders = Order.by_vendor.by_user.order("id DESC").page(params[:page]).per(GlobalData.conf.pagination)
      else
        @orders = Order.by_vendor.by_user.where("id = '#{params[:keywords]}' or tag LIKE '%#{params[:keywords]}%'").page(params[:page]).per(GlobalData.conf.pagination)
      end
    else
      @customers = Customer.scopied.page(params[:page]).per(GlobalData.conf.pagination)
    end
  end
  def item_json
    @item = Item.all_seeing.find_by_sku(params[:sku], :select => "name,sku,id")
  end
  def edit_location
    respond_to do |format|
      format.html 
      format.js { render :content_type => 'text/javascript',:layout => false}
    end
  end

  def labels
    if params[:user_type] == 'User'
      @user = User.find_by_id(params[:user_id])
    else
      @user = Employee.find_by_id(params[:user_id])
    end
    @register = CashRegister.find_by_id(params[:cash_register_id])
    @vendor = @register.vendor if @register
    #`espeak -s 50 -v en "#{ params[:cash_register_id] }"`
    render :nothing => true and return if @register.nil? or @vendor.nil? or @user.nil?

    if params[:id]
      @items = Item.find_all_by_id(params[:id])
    elsif params[:skus]
      @items = Item.where(:sku => params[:skus].split(","))
    end
    text = Printr.new.sane_template(params[:type],binding)
    if @register.salor_printer
      render :text => text
      #`beep -f 2000 -l 10 -r 3`
    else
      printer_path = params[:type] == 'sticker' ? @register.sticker_printer : @register.thermal_printer
      File.open(printer_path,'w:ISO-8859-15') { |f| f.write text }
      render :nothing => true
    end
  end

  def database_distiller
    @used_item_ids = OrderItem.all.collect{ |oi| oi.item.id }.uniq
    @relevant_item_ids = Item.where('quantity = 0 and quantity_sold = 0 and hidden = 0 and hidden_by_distiller = 0').collect{ |i| i.id }
    @unused_item_ids = @relevant_item_ids - @used_item_ids
    @hidden = Item.where('hidden = 1')
    @hidden_by_distiller = Item.where('hidden_by_distiller = 1')
    @unused_item_ids = @relevant_item_ids - @used_item_ids
  end

  def distill_database
    used_item_ids = OrderItem.all.collect{ |oi| oi.item.id }.uniq
    relevant_item_ids = Item.where('quantity = 0 and quantity_sold = 0').collect{ |i| i.id }
    unused_item_ids = relevant_item_ids - used_item_ids
    unused_item_ids.each do |ui|
      item = Item.find_by_id(ui)
      item.update_attributes :child_id => nil, :hidden_by_distiller => true, :hidden => true, :sku => (1000 + rand(99999)).to_s[0..3] + 'OLD:' + item.sku
    end
    GlobalErrors << unused_item_ids.count
    redirect_to '/items/database_distiller'
  end

  def export_broken_items
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    if params[:from] then
      @items = BrokenItem.scopied.where(["created_at between ? and ?", @from, @to])
      text = []
      if @items.any? then
        text << @items.first.csv_header
      end
      @items.each do |item|
        text << item.to_csv
      end
      render_csv "broken_items", text.join("\n") and return
    end
  end
  
  def reorder_recommendation
    text = Item.recommend_reorder(params[:type])
    if not text.nil? and not text.empty? then
      send_data text,:filename => "Reorder" + Time.now.strftime("%Y%m%d%H%I") + ".csv", :type => "application/x-csv"
    else
      redirect_to :action => :index, :notice => I18n.t("system.errors.cannot_reorder")
    end
    
  end

  def upload
    if params[:file]
      lines = params[:file].read.split("\n")
      # This works like x,y,z = list(array) in PHP, i.e. multiple assignment from an array. Just FYI
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.salor(lines)
      redirect_to(:action => 'upload')
    end
  end

  def upload_danczek_tobaccoland_plattner
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type1(lines)
      redirect_to(:action => 'index')
    end
  end

  def upload_house_of_smoke
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type2(lines)
      redirect_to(:action => 'index')
    end
  end

  def upload_optimalsoft
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type3(lines)
      redirect_to(:action => 'index')
    end
  end
  
  def wholesaler_update
    a = Mechanize.new
    uploader = FileUpload.new
    GlobalData.conf.csv_imports.split("\n").each do |line|
      parts = line.chomp.split(',')
      next if parts[0].nil?
      begin
      if parts[0].include? 'http://' or parts[0].include? 'https://' then
        file = a.get(parts[0])
      else
        file = a.get(GlobalData.conf.csv_imports_url + "/" + parts[0])
      end
      if parts[1].include? "dist*" then
        uploader.send('dist'.to_sym, file.body,true) # i.e. dist* means an internal source
      elsif parts[1] == 'dist' then
        uploader.send(parts[1].to_sym, file.body,false) # just dist means that it is the new salor format, but not trusted
      else
        uploader.send(parts[1].to_sym, file.body.split("\n")) # i.e. we dynamically call the function to process
      end
      # this .csv file, this is set in the vendor.salor_configuration as filename.csv,type1|type2 ...
      rescue
        GlobalErrors << ["WholeSaleImportError",$!.to_s + " For " + parts[0].to_s,nil]
      end
    end
    respond_to do |format|
      format.html { render :text => "Complete"}
      format.js { render :content_type => 'text/javascript',:layout => false}
    end
  end

  def download
    @items = Item.scopied.where(:hidden => false)
    render 'list.csv'
  end

  def inventory_report
    add_breadcrumb I18n.t("menu.update_real_quantity"), items_update_real_quantity_path
    add_breadcrumb I18n.t("menu.inventory_report"), items_inventory_report_path
    @items = Item.scopied.where('real_quantity > 0')
    @items.inspect
    @categories = Category.scopied
  end

  private 
  def crumble
    @vendor = salor_user.get_vendor(salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.items"),'items_path(:vendor_id => params[:vendor_id])'
  end
  # {END}
end
