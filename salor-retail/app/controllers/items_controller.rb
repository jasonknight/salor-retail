# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class ItemsController < ApplicationController
  before_filter :check_role, :except => [:info, :search]
  before_filter :update_devicenodes, :only => [:index]
  

  def index
    orderby = "id DESC"
    orderby ||= params[:order_by]
    
    if params[:keywords] and params[:keywords].blank?
      # user has cleared the field
      @keywords = session[:keywords] = nil
    elsif not params[:keywords].blank?
      @keywords = session[:keywords] = params[:keywords]
    elsif not session[:keywords].blank?
      @keywords = session[:keywords]
    end
    
    if @keywords
      @items = @current_vendor.items.by_keywords(@keywords).visible.where("items.sku NOT LIKE 'DMY%'")
      child_item_skus = []
      log_action "XXXXX[recursive find]: @items #{ @items.collect{ |i| i.sku } }"
      @items.each do |i|
        log_action "XXXXX[recursive find]: finding upmost parent for Item id #{ i.id }"
        upmost_parent_sku = i.recursive_parent_sku_chain.last
        log_action "XXXXX[recursive find]: upmost parent sku is #{ upmost_parent_sku }"
        upmost_parent = @current_vendor.items.visible.find_by_sku(upmost_parent_sku)
        
        bottom_most_child = upmost_parent.recursive_child_sku_chain.last
        log_action "XXXXX[recursive find]: bottom most child sku is #{ bottom_most_child }"
        child_item_skus << bottom_most_child
      end
      @items = @current_vendor.items.visible.where(:sku => child_item_skus).page(params[:page]).per(@current_vendor.pagination)
    else
      @items = @current_vendor.items.visible.where("items.sku NOT LIKE 'DMY%'").where('child_id = 0 or child_id IS  NULL').page(params[:page]).per(@current_vendor.pagination).order(orderby)
    end
  end

  def show
    if params[:keywords] then
      @item = @current_vendor.items.visible.by_keywords(params[:keywords]).first
    end

    @item ||= @current_vendor.items.visible.find_by_id(params[:id])

    redirect_to items_path if not @item
    
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : 1.month.ago.beginning_of_day
    @to = @to ? @to.end_of_day : DateTime.now
    @sold_times = @current_vendor.order_items.visible.where(:sku => @item.sku, :refunded => nil, :completed_at => @from..@to, :is_quote => nil, :is_proforma => nil).where("is_buyback = false OR is_buyback IS NULL").sum(:quantity)
  end

  
  def new
    @item = @current_vendor.items.build
    @histories = @item.histories.order("created_at DESC").limit(20)
  end

  def edit
    @item = @current_vendor.items.visible.where(["id = ? or sku = ?",params[:id],params[:keywords]]).first
    if @item
      @histories = @item.histories.order("created_at DESC").limit(20)
      #@item.item_stocks.build if not @item.item_stocks.any?
      #@item.item_shippers.build if not @item.item_shippers.any?
    else
      $MESSAGES[:notices] << "Not found"
      redirect_to items_path
    end
  end


  def create
    @item = Item.new
    @item.vendor = @current_vendor
    @item.company = @current_company
    @item.currency = @current_vendor.currency
    @item.created_by = @current_user.id
    @item.attributes = params[:item]
    if @item.save
      @item.assign_parts(params[:part_skus])
      @item.item_stocks.update_all :vendor_id => @item.vendor_id, :company_id => @item.company_id
      @item.item_shippers.update_all :vendor_id => @item.vendor_id, :company_id => @item.company_id
      redirect_to items_path
    else
      @histories = @item.histories.order("created_at DESC").limit(20)
      render :new
    end
  end
  
#   # from shipment form
#   def create_ajax
#     @item = Item.new
#     @item.vendor = @current_vendor
#     @item.company = @current_company
#     @item.currency = @current_vendor.currency
#     @item.item_type = @current_vendor.item_types.find_by_behavior("normal")
#     @item.tax_profile_id = params[:item][:tax_profile_id]
#     @item.attributes = params[:item]
#     @item.save
#     render :nothing => true
#   end

  def update
    @item = @current_vendor.items.visible.find_by_id(params[:id])
    params[:item][:currency] = @current_vendor.currency
    
    @item.attributes = params[:item]
    if @item.save == true
      @item.assign_parts(params[:part_skus])
      @item.item_stocks.update_all :vendor_id => @item.vendor_id, :company_id => @item.company_id
      @item.item_shippers.update_all :vendor_id => @item.vendor_id, :company_id => @item.company_id
      @histories = @item.histories.order("created_at DESC").limit(20)
      redirect_to items_path
    else
      @histories = @item.histories.order("created_at DESC").limit(20)
      render :edit
    end
  end
  
  def gift_cards
    @gift_cards_sold = @current_vendor.order_items.visible.where(:behavior => "gift_card", :activated => nil, :paid => true)
  end

  def destroy
    @item = @current_vendor.items.visible.find_by_id(params[:id])
    @item.hide(@current_user.id)
    redirect_to items_path
  end
  
  def info
    if params[:sku] then
      @item = Item.find_by_sku(params[:sku])
    else
      @item = Item.find(params[:id]) if Item.exists? params[:id]
    end
  end

  def search
    @items = []
    @customers = []
    @orders = []
    
    if params[:klass] == 'Item' then
      if params[:keywords].empty? then
        @items = @current_vendor.items.visible.page(params[:page]).per(@current_vendor.pagination)
      else
        @items = @current_vendor.items.visible.by_keywords(params[:keywords]).page(params[:page]).per(@current_vendor.pagination)
      end
    elsif params[:klass] == 'Order'
      if params[:keywords].empty? then
        @orders = @current_vendor.orders.order("nr DESC").page(params[:page]).per(@current_vendor.pagination)
      else
        @orders = @current_vendor.orders.where("nr = '#{params[:keywords]}' or tag LIKE '%#{params[:keywords]}%'").page(params[:page]).per(@current_vendor.pagination)
      end
    elsif params[:klass] == 'Customer'
      @customers = @current_company.customers.visible.where("first_name LIKE '%#{params[:keywords]}%' OR last_name LIKE '%#{params[:keywords]}%'").page(params[:page]).per(@current_vendor.pagination)
    end
  end
  
  def edit_location
    respond_to do |format|
      format.html 
      format.js { render :content_type => 'text/javascript',:layout => false}
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
  
  def reorder_recommendation
    text = Item.recommend_reorder(params[:type])
    if not text.nil? and not text.empty? then
      send_data text,:filename => "Reorder" + Time.now.strftime("%Y%m%d%H%I") + ".csv", :type => "application/x-csv"
    else
      redirect_to :action => :index, :notice => I18n.t("system.errors.cannot_reorder")
    end
    
  end

  def upload
    if params[:file] and params[:file].content_type == "text/csv" then
      shipper = Shipper.new( :name => "Salor")
      shipper.vendor = @current_vendor
      shipper.company = @current_company

      if shipper then
        @uploader = FileUpload.new(shipper, params[:file].read)
        @uploader.salor(true) #i.e. trusted
      end
    end
    render :text => "Done", :status => 200 and return
  end
  
  def download
    params[:page] ||= 1
    params[:order_by] = "id DESC" if not params[:order_by] or params[:order_by].blank?
    orderby ||= params[:order_by]
    unless params[:keywords].blank?
      # search function should display recursive items
      @items = @current_vendor.items.by_keywords(params[:keywords]).visible.where("items.sku NOT LIKE 'DMY%'").page(params[:page]).per(@current_vendor.pagination).order(orderby)
    else
      @items = @current_vendor.items.visible.where("items.sku NOT LIKE 'DMY%'").where('child_id = 0 or child_id IS  NULL').page(params[:page]).per(@current_vendor.pagination).order(orderby)
    end
    data = render_to_string :layout => false
    send_data(data,:filename => 'items.csv', :type => 'text/csv')
  end
  
  def selection
    if params[:order_id]
      order = @current_vendor.orders.visible.find_by_id(params[:order_id])
      @skus = "ORDER#{order.id}"
    else
      @skus = nil
    end
  end
  
  def labels
    output = @current_vendor.print_labels('item', params, @current_register)
    if params[:download] == 'true'
      send_data output, :filename => '1.salor'
      return
    elsif @current_register.salor_printer
      render :text => output
      return
    end
    render :nothing => true
  end
  
  def report
    @items = @current_vendor.items.select("items.quantity,items.name,items.sku,items.price_cents,items.category_id,items.location_id,items.id,items.vendor_id,items.currency").visible.includes(:location,:category).by_keywords(params[:keywords]).page(params[:page]).per(10)
    @view = SalorRetail::Application::CONFIGURATION[:reports][:style]
    @view ||= 'default'
    render "items/reports/#{@view}/page"
  end

  def new_action
    item = @current_vendor.items.visible.find_by_id(params[:item_id])
    action = item.create_action
    redirect_to action_path(action)
  end
end
