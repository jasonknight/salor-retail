# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class OrdersController < ApplicationController

  respond_to :html, :xml, :json, :csv
  after_filter :customerscreen_push_notification, :only => [:add_item_ajax, :delete_order_item]
  before_filter :update_devicenodes, :only => [:new, :new_order]

   
  def new_from_proforma
    @proforma = @current_vendor.orders.visible.find_by_id(params[:order_id])
    @order = @proforma.make_from_proforma_order
    @order.user = @current_user
    @order.save
    redirect_to edit_order_path(@order)
  end
  
  def merge_into_current_order
    @current = @current_vendor.orders.find_by_id(params[:order_id])
    @to_merge = @current_vendor.orders.find_by_id(params[:id])
    @to_merge.order_items.visible.each do |oi|
       noi = oi.dup
       noi.order_id = @current.id
       noi.save
    end
    redirect_to edit_order_path(@current)
  end
  
  def index
    params[:type] ||= 'normal'
    case params[:type]
    when 'normal'
      @orders = @current_vendor.orders.order("nr desc").where(:paid => true).page(params[:page]).per(@current_vendor.pagination)
    when 'proforma'
      @orders = @current_vendor.orders.order("nr desc").where(:is_proforma => true).page(params[:page]).per(@current_vendor.pagination)
    when 'unpaid'
      @orders = @current_vendor.orders.order("nr desc").where(:is_unpaid => true).page(params[:page]).per(@current_vendor.pagination)
    when 'quote'
      @orders = @current_vendor.orders.order("qnr desc").where(:is_quote => true).page(params[:page]).per(@current_vendor.pagination)
    else
      @orders = @current_vendor.orders.order("id desc").page(params[:page]).per(@current_vendor.pagination)
    end
  end

  def show
    @order = @current_vendor.orders.visible.find_by_id(params[:id])
  end

  def new
    # get the user's current order
    @current_order = @current_vendor.orders.visible.where(:completed_at => nil).find_by_id(@current_user.current_order_id)

    # create a new order if the previous fails
    unless @current_order
      @current_order = Order.new
      @current_order.vendor = @current_vendor
      @current_order.company = @current_company
      @current_order.currency = @current_vendor.currency
      @current_order.user = @current_user
      @current_order.cash_register = @current_register
      @current_order.drawer = @current_user.get_drawer
      @current_order.save
      
      # remember this for the current user
      @current_user.current_order_id = @current_order.id
      @current_user.save
    end
 
    @button_categories = @current_vendor.categories.visible.where(:button_category => true).order(:position)
  end


  def edit
    requested_order = @current_vendor.orders.visible.where(:completed_at => nil).find_by_id(params[:id])
    
    if requested_order.nil?
      # the requested order is already completed. We cannot edit that and rediect to #new.
      redirect_to new_order_path
      return
    end
    
    user_which_has_requested_order = @current_vendor.users.visible.find_by_current_order_id(requested_order.id)
    
    if user_which_has_requested_order and user_which_has_requested_order != @current_user
      # another user is editing this order. We cannot edit that and redirect to #new.
      redirect_to new_order_path
      return
    end
    
    # the order is available for editing
    @current_user.current_order_id = requested_order.id
    @current_user.save
    redirect_to new_order_path
  end


  def add_item_ajax
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
    @order_item = @order.add_order_item(params)
    @order_items = []
    
    if @order_item
      @order_items << @order_item
      
      if @order_item.behavior == 'coupon'
        @matching_coupon_item = @order.order_items.visible.find_by_sku(@order_item.item.coupon_applies)
        @order_items << @matching_coupon_item
      end
    else
      # if it was a scanned Loyalty card, @order_item is nil. Else clause must stay empty.
    end
    render :update_pos_display
  end


  def delete_order_item
    @order_item = @current_vendor.order_items.find_by_id(params[:id])
    @order = @order_item.order
    @order_item.hide(@current_user)
    @order_items = []
    if @order_item.behavior == 'coupon'
      @matching_coupon_item = @order.order_items.visible.find_by_sku(@order_item.item.coupon_applies)
      @order_items << @matching_coupon_item
    end
    render :update_pos_display
  end

  def print_receipt
    @order = @current_vendor.orders.visible.find_by_id(params[:order_id])    
    if @current_register.salor_printer
      contents = @order.escpos_receipt
      output = Escper::Printer.merge_texts(contents[:text], contents[:raw_insertations])
      if params[:download] then
        send_data(output, {:filename => 'salor.bill'})
      else
        render :text => output and return
      end
    else
      @order.print(@current_register)
      render :nothing => true and return
    end
      
    r = Receipt.new
    r.vendor = @current_vendor
    r.company = @current_company
    r.order = @order
    r.user = @current_user
    r.drawer = @current_drawer
    r.content = contents[:text]
    r.ip = request.ip
    r.save
  end

  def print_confirmed
    o = Order.find_by_id params[:order_id]
    
    o.update_attribute :was_printed, true if o
    render :nothing => true
  end
  
  def last_five_orders
    @text = render_to_string('shared/_last_five_orders',:layout => false)
    render :text => @text
  end
  
  # ajax
  def complete
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])

    History.record("Initialized order for complete", @order, 5)

    if params[:user_id] and params[:user_id] != @current_user.id then
      tmp_user = User.find_by_id(params[:user_id])
      if tmp_user and tmp_user.vendor_id == @current_user.vendor_id then
        tmp_user.update_attribute :current_register_id, @current_register
        History.record("swapped user #{@current_user.id} with #{tmp_user.id}",@order,3)
        @current_user = tmp_user
        @order.update_attribute :user_id, @current_user.id
        SalorBase.log_action("OrdersController","tmp_user swapped")
      else
        SalorBase.log_action("OrdersController","tmp_user does not belong to this store")
        render :js => "alert('InCorrectUser');" and return
      end
    end
    
    @order.user = @current_user
    @order.complete(params)

    if @order.is_proforma == true then
      History.record("Order is proforma, completing",@order,5)
      render :js => " window.location = '/orders/#{@order.id}/print'; " and return
    end
    
    customerscreen_push_notification
    
    @old_order = @order # needed for a feature which allows change money calculation even after the order was completed.
    
    @order = Order.new
    @order.vendor = @current_vendor
    @order.company = @current_company
    @order.currency = @current_vendor.currency
    @order.user = @current_user
    @order.drawer = @current_user.get_drawer
    @order.cash_register = @current_register
    result = @order.save
    raise "Could not create a new order in OrdersController#complete because #{ @order.errors.messages }" unless result == true
    
    # save new order on user
    @current_user.current_order_id = @order.id
    @current_user.save
  end
  
  def new_order
    o = Order.new
    o.vendor = @current_vendor
    o.company = @current_company
    o.currency = @current_vendor.currency
    o.user = @current_user
    o.drawer = @current_user.get_drawer
    o.cash_register = @current_register
    o.save
    
    # save new order on user
    @current_user.current_order_id = o.id
    @current_user.save
    redirect_to new_order_path
  end
  
  def split_order_item
    @oi = @current_vendor.order_items.visible.find_by_id(params[:id])
    @oi.split
    redirect_to request.referer
  end
  
  def refund_item
    @oi = @current_vendor.order_items.visible.find_by_id(params[:id])
    @oi.refund(params[:pm], @current_user)
    redirect_to request.referer
  end
  
  def customer_display
    @order = @current_vendor.orders.visible.find_by_id(params[:id])
    @order_items = @order.order_items.visible.order('id ASC')
    @report = @order.report
    @ec = @current_vendor.currency # @ex is exchange_to currency
    render :layout => 'customer_display'
  end
  
  def receipts
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : Time.now.end_of_day
    cash_register_id = params[:cash_register_id]
    cash_register_id ||= @current_register.id
    @receipts = @current_vendor.receipts.where(:created_at => @from..@to, :cash_register_id => cash_register_id)
  end
  
  def print
    @order = @current_vendor.orders.visible.find_by_id(params[:id])
    @report = @order.report(params[:locale_select])
    # exchange to currency
    @ec = params[:currency]
    @ec ||= @current_vendor.currency
    view = 'default'
    render "orders/invoices/#{view}/page"
  end

  
  def clear
    if not @current_user.can(:clear_orders) then
      History.record(:failed_to_clear, @order, 1)
      render 'update_pos_display' and return
    end
    
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
    
    if @order then
      History.record("Destroying #{@order.order_items.visible.count} OrderItems", @order, 1)
      
      @order.order_items.visible.each do |oi|
        oi.hidden = 1
        oi.hidden_by = @current_user.id
        oi.save
      end
      
      @order.customer_id = nil
      @order.tag = nil
      @order.subtotal = 0
      @order.total = 0
      @order.tax = 0
      @order.save
    else
      History.record("cannot clear order because already paid", @order, 1)
    end
    render 'update_pos_display' and return
  end
  
  def log
    h = History.new
    h.url = "/orders/log"
    h.params = params
    h.model_id = params[:order_id]
    h.model_type = 'Order'
    h.action_taken = params[:log_action]
    h.changes_made = params[:called_from]
    h.save
    render :nothing => true
  end
end
