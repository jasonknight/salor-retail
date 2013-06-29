# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
require 'rubygems'
require 'mechanize'
class ItemsController < ApplicationController
  # {START}
  before_filter :check_role, :except => [:info, :search, :labels, :crumble, :wholesaler_update]
  before_filter :crumble, :except => [:wholesaler_update, :labels]
  
  # GET /items
  # GET /items.xml
  def index
    CashRegister.update_all_devicenodes
    if params[:order_by] then
      key = params[:order_by]
      session[key] = (session[key] == 'DESC') ? 'ASC' : 'DESC'
      @items = Item.scopied.where("items.sku NOT LIKE 'DMY%'").page(params[:page]).per($Conf.pagination).order("#{key} #{session[key]}")
    else
      @items = Item.scopied.where("items.sku NOT LIKE 'DMY%'").page(params[:page]).per($Conf.pagination).order("id desc")
    end
    
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
    if params[:id] and not params[:keywords] then
      @item = $Vendor.items.find_by_id(params[:id])
    end
    if params[:keywords] then
        @item = $Vendor.items.by_keywords.first
    end
    if not @item then
      redirect_to "/items?notice=" + I18n.t('system.errors.item_not_found') and return
    end
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : 1.month.ago.beginning_of_day
    @to = @to ? @to.end_of_day : DateTime.now
    @sold_times = OrderItem.scopied.find(:all, :conditions => {:sku => @item.sku, :hidden => 0, :is_buyback => false, :refunded => false, :created_at => @from..@to}).collect do |i| 
      (i.order.paid == 1 and not i.order.is_proforma) ? i.quantity : 0 
    end.sum
  end

  # GET /items/new
  # GET /items/new.xml
  def new
    @item = Item.new(:vendor_id => @current_user.vendor_id)
    @item.item_shippers.build
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
    @item.item_stocks.build if not @item.item_stocks.any?
    @item.item_shippers.build if not @item.item_shippers.any?
    add_breadcrumb @item.name,'edit_item_path(@item,:vendor_id => params[:vendor_id])'
   
  end

  # POST /items
  # POST /items.xml
  def create
    # We must insure that tax_profile is set first, otherwise, the
    # gross magic won't work
    # TODO Test this as it's no longer necessary
    if params[:item][:price_by_qty].to_i == 1 then
      params[:item][:price_by_qty] = true
    else
      params[:item][:price_by_qty] = false
    end
    @item = Item.all_seeing.find_by_sku(params[:item][:sku])
    if @item then
      @item.attributes = params[:item]
      @item.save
      flash[:notice] = I18n.t('system.errors.sku_must_be_unique',:sku => @item.sku)
      render :action => "new" and return
    end

    @item = Item.new
    @item.tax_profile_id = params[:item][:tax_profile_id]
    @item.attributes = params[:item]
    @item.sku.upcase!
    @item.set_model_owner(@current_user)
    respond_to do |format|
      if @item.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Item.model_name.human)) }
        format.xml  { render :xml => @item, :status => :created, :location => @item }
      else
        format.html { render :action => "new", :notice => "Failed" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def create_ajax
    @item = Item.new()
    @item.tax_profile_id = params[:item][:tax_profile_id]
    @item.attributes = params[:item]
    respond_to do |format|
      if @current_user.owns_vendor?(@item.vendor_id) and @item.save
        @item.set_model_owner(@current_user)
        format.json  { render :json => @item }
      else
        format.json  { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.scopied.find_by_id(params[:id])
    params[:item][:sku].upcase!
    if params[:item][:price_by_qty].to_i == 1 then
      params[:item][:price_by_qty] = true
    else
      params[:item][:price_by_qty] = false
    end
    
    @item.attributes = params[:item]
    @item.save
    respond_to do |format|
      if not @item.errors.messages.any?
        @item.set_model_owner(@current_user)
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
      @item.update_attribute(:real_quantity_updated, true)
    end
  end
  def move_real_quantity
    ir = InventoryReport.create(:name => "AutoGenerated #{Time.now}", :created_at => Time.now, :updated_at => Time.now, :vendor_id => @current_user.vendor_id)
    sql = %Q[
        insert into inventory_report_items 
        ( inventory_report_id,
          item_id,
          real_quantity,
          item_quantity,
          created_at,
          updated_at,
          vendor_id
         ) select 
            ir.id,
            i.id,
            i.real_quantity,
            i.quantity,
            NOW(),
            NOW(),
            ir.vendor_id from 
          items as i, 
          inventory_reports as ir where 
            i.real_quantity_updated IS TRUE and 
            ir.id = #{ir.id}
  ]
    Item.connection.execute(sql)
    Item.connection.execute("update items set quantity = real_quantity, real_quantity_updated = FALSE where real_quantity_updated IS TRUE")
    redirect_to items_update_real_quantity_path, :notice => t('views.notice.move_real_quantities_success')
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find_by_id(params[:id])
    if @current_user.owns_this?(@item) then
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
  #
  def search
    if not @current_user.owns_vendor? @current_user.vendor_id then
      @current_user.vendor_id = salor_user.get_default_vendor.id
    end
    @items = []
    @customers = []
    @orders = []
    if params[:klass] == 'Item' then
      @items = Item.scopied.page(params[:page]).per($Conf.pagination)
    elsif params[:klass] == 'Order'
      if params[:keywords].empty? then
        @orders = Order.by_vendor.by_user.order("id DESC").page(params[:page]).per($Conf.pagination)
      else
        @orders = Order.by_vendor.by_user.where("id = '#{params[:keywords]}' or nr = '#{params[:keywords]}' or tag LIKE '%#{params[:keywords]}%'").page(params[:page]).per($Conf.pagination)
      end
    else
      @customers = Customer.scopied.page(params[:page]).per($Conf.pagination)
    end
  end
  def item_json
    @item = Item.all_seeing.find_by_sku(params[:sku], :select => "name,sku,id,purchase_price")
  end
  def edit_location
    respond_to do |format|
      format.html 
      format.js { render :content_type => 'text/javascript',:layout => false}
    end
  end

  # due to salor-bin this can't rely on session
  def labels
    if params[:user_type] == 'User'
      @user = User.find_by_id(params[:user_id])
    else
      @user = User.find_by_id(params[:user_id])
    end
    @register = CashRegister.find_by_id(params[:current_register_id])
    @vendor = @register.vendor if @register
    #`espeak -s 50 -v en "#{ params[:current_register_id] }"`
    render :text => "No User#{@user}, or Register#{@register}, or Vendor#{@vendor}" and return if @register.nil? or @vendor.nil? or @user.nil?

    if params[:id]
      @items = Item.find_all_by_id(params[:id])
    elsif params[:skus]
      match = /(ORDER)(.*)/.match(params[:skus].split(",").first)
      if match[1] == 'ORDER'
        order_id = match[2].to_i
        @order_items = Order.find_by_id(order_id).order_items.visible
        @items = []
      else
        @order_items = []
        @items = Item.where(:sku => params[:skus].split(","))
      end
    end
    @currency = I18n.t('number.currency.format.friendly_unit')
    template = File.read("#{Rails.root}/app/views/printr/#{params[:type]}_#{params[:style]}.prnt.erb")
    erb = ERB.new(template, 0, '>')
    text = erb.result(binding)
      
    if params[:download] == 'true'
      send_data Escper::Asciifier.new.process(text), :filename => '1.salor' and return
    elsif @register.salor_printer
      render :text => Escper::Asciifier.new.process(text) and return
    else
      printer_path = params[:type] == 'sticker' ? @register.sticker_printer : @register.thermal_printer
      vendor_printer = VendorPrinter.new :path => printer_path
      print_engine = Escper::Printer.new('local', vendor_printer)
      print_engine.open
      print_engine.print(0, text)
      print_engine.close
      render :nothing => true and return
    end
  end

  def database_distiller
    @all_items = Item.where(:hidden => 0).count
    @used_item_ids = OrderItem.connection.execute('select item_id from order_items').to_a.flatten.uniq
    @hidden = Item.where('hidden = 1')
    @hidden_by_distiller = Item.where('hidden_by_distiller = 1')
  end

  def distill_database
    all_item_ids = Item.connection.execute('select id from items').to_a.flatten.uniq
    used_item_ids = OrderItem.connection.execute('select item_id from order_items').to_a.flatten.uniq
    deletion_item_ids = all_item_ids - used_item_ids
    Item.where(:id => deletion_item_ids).update_all(:hidden => 1, :hidden_by_distiller => true, :child_id => nil, :sku => nil)
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
#       lines = params[:file].read.split("\n")
      # This works like x,y,z = list(array) in PHP, i.e. multiple assignment from an array. Just FYI
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.dist(params[:file].read,true)
      redirect_to(:action => 'upload')
    end
  end

  def upload_danczek_tobaccoland_plattner
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type1("tobaccoland", lines)
      redirect_to(:action => 'index')
    end
  end

  def upload_house_of_smoke
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type2("dios", lines)
      redirect_to(:action => 'index')
    end
  end

  def upload_optimalsoft
    if params[:file]
      lines = params[:file].read.split("\n")
      i, updated_items, created_items, created_categories, created_tax_profiles = FileUpload.new.type3("Optimalsoft", lines)
      redirect_to(:action => 'index')
    end
  end
  
  def wholesaler_update
    
    uploader = FileUpload.new
    @report = { :updated_items => 0, :created_items => 0, :created_categories => 0, :created_tax_profiles => 0 }
    $Conf.csv_imports.split("\n").each do |line|
      parts = line.chomp.split(',')
      next if parts[0].nil?
      
      if parts[0].include? 'http://' or parts[0].include? 'https://' then
        file = get_url(parts[0],parts[3],parts[4])
      else
        file = get_url($Conf.csv_imports_url + "/" + parts[0],parts[3],parts[4])
      end
      
      if parts[1].include? "dist*" then
        ret = uploader.send('dist'.to_sym, parts[2], file.body,true) # i.e. dist* means an internal source
      elsif parts[1] == 'dist' then
        ret = uploader.send(parts[1].to_sym, parts[2], file.body,false) # just dist means that it is the new salor format, but not trusted
      else
        ret = uploader.send(parts[1].to_sym, parts[2], file.body.split("\n")) # i.e. we dynamically call the function to process
      end
      # this .csv file, this is set in the vendor.salor_configuration as filename.csv,type1|type2 ...
      ret.each do |k,v|
        @report[k] += v
      end
    end
    respond_to do |format|
      format.html 
      format.js { render :content_type => 'text/javascript',:layout => false}
    end
  end

  def download
    params[:page] ||= 1
    params[:order_by] ||= "created_at"
    params[:order_by] = "created_at" if not params[:order_by] or params[:order_by].blank?
    if params[:order_by] then
      key = params[:order_by]
      session[key] ||= 'ASC'
      @items = Item.scopied.where("items.sku NOT LIKE 'DMY%'").page(params[:page]).per($Conf.pagination).order("#{key} #{session[key]}")
    else
      @items = Item.scopied.where("items.sku NOT LIKE 'DMY%'").page(params[:page]).per($Conf.pagination).order("id desc")
    end
    data = render_to_string :layout => false
    send_data(data,:filename => 'items.csv', :type => 'text/csv')
  end

  def inventory_report
    add_breadcrumb I18n.t("menu.update_real_quantity"), items_update_real_quantity_path
    add_breadcrumb I18n.t("menu.inventory_report"), items_inventory_report_path
    @items = Item.scopied.where(:real_quantity_updated => true)
    @categories = Category.scopied
  end
  
  def selection
    if params[:order_id]
      order = Order.scopied.find_by_id(params[:order_id])
      @skus = "ORDER#{order.id}"
      #order.order_items.visible.collect{ |oi| "{OI#{oi.id}}" }.join("\n")
    else
      @skus = nil
    end
  end
  def report
    @items = $Vendor.items.select("items.quantity,items.name,items.sku,items.base_price,items.category_id,items.location_id,items.id,items.vendor_id").visible.includes(:location,:category).by_keywords.page(params[:page]).per(100)
    @view = SalorRetail::Application::CONFIGURATION[:reports][:style]
    @view ||= 'default'
    render "items/reports/#{@view}/page"
  end
  private 
  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.items"),'items_path(:vendor_id => params[:vendor_id])'
  end
  # {END}
end
