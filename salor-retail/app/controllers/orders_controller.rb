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
    @proforma = Order.scopied.find_by_id(params[:order_id].to_s)
    @order = @proforma.dup
    @order.save
    @order.reload
    @proforma.order_items.visible.each do |oi|
       noi = oi.dup
       noi.order_id = @order.id
       noi.save
    end
    item = Item.get_by_code("DMYACONTO")
    item.update_attribute :name, I18n.t("receipts.a_conto")
    item.make_valid
    @order.update_attribute :paid, 0
    noi = @order.add_item(item)
    noi.price = @proforma.amount_paid * -1
    noi.is_buyback = true
    noi.save
    @order.is_proforma = false

    redirect_to "/orders/new?order_id=#{@order.id}"
  end
  
  def merge_into_current_order
    @current = @current_vendor.orders.find_by_id(params[:order_id])
    @to_merge = @current_vendor.orders.find_by_id(params[:id])
    @to_merge.order_items.visible.each do |oi|
       noi = oi.dup
       noi.order_id = @current.id
       noi.save
    end
    redirect_to "/orders/new?order_id=#{@current.id}"
  end
  
  def index
    params[:type] ||= 'normal'
    case params[:type]
    when 'normal'
      @orders = @current_vendor.orders.order("nr desc").where(:paid => true).page(params[:page]).per(@current_vendor.pagination)
    when 'proforma'
      @orders = @current_vendor.orders.order("nr desc").where(:is_proforma => true).page(params[:page]).per(@current_vendor.pagination)
    when 'unpaid'
      @orders = @current_vendor.orders.order("nr desc").unpaid.page(params[:page]).per(@current_vendor.pagination)
    when 'quote'
      @orders = @current_vendor.orders.order("qnr desc").quotes.page(params[:page]).per(@current_vendor.pagination)
    else
      @orders = @current_vendor.orders.order("id desc").page(params[:page]).per(@current_vendor.pagination)
    end
  end


  def show
    @order = @current_vendor.orders.visible.find_by_id(params[:id])
  end

  def new    
    # get an order from params
    if params[:order_id].to_i != 0 then
      @current_order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
    end
    
    # get user's last order if unpaid
    unless @current_order
      @current_order = @current_vendor.orders.where(:paid => nil).find_by_id(@current_user.current_order_id)
    end
    
    # create new order if all of the previous fails
    unless @current_order
      @current_order = Order.new
      @current_order.vendor = @current_vendor
      @current_order.company = @current_company
      @current_order.user = @current_user
      @current_order.cash_register = @current_register
      @current_order.drawer = @current_user.get_drawer
      @current_order.save
      @current_user.current_order_id = @current_order.id
      @current_user.save
    end
 
    @button_categories = Category.where(:button_category => true).order(:position)
    @current_register.reload
  end


  def edit
    @current_user.current_order_id = params[:id]
    @current_user.save
    redirect_to new_order_path
  end


  def add_item_ajax
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
    @order_item = @order.add_order_item(params)
  end


  def delete_order_item
    oi = @current_vendor.order_items.find_by_id(params[:id])
    @order = oi.order
    oi.hide(@current_user)
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


  def show_payment_ajax
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
  end
  
  def last_five_orders
    @text = render_to_string('shared/_last_five_orders',:layout => false)
    render :text => @text
  end
  
  def complete
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
    
    SalorBase.log_action("OrdersController","complete_order_ajax order initialized")
    History.record("initialized order for complete",@order,5)

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
    
    if params[:print] and @current_register.salor_printer != true and not @current_register.thermal_printer.blank?
      @order.print(@current_register)
    end
    
    customerscreen_push_notification
    
    @old_order = @order
    
    @order = Order.new
    @order.vendor = @current_vendor
    @order.company = @current_company
    @order.user = @current_user
    @order.cash_register = @current_register
    @order.save
    @current_user.current_order_id = @order.id
    @current_user.save
    
    
  end
  
  def new_order
    o = Order.new
    o.vendor = @current_vendor
    o.company = @current_company
    o.user = @current_user
    o.drawer = @current_user.get_drawer
    o.cash_register = @current_register
    o.save
    @current_user.current_order_id = o.id
    @current_user.save
    redirect_to new_order_path
  end
  
  def activate_gift_card
    @error = nil
    @order = initialize_order
    @order_item = @order.activate_gift_card(params[:id],params[:amount])
    if not @order_item then
      History.record("Failed to activate gift card",@order,5)
      @error = true
    else
      History.record("Activated Gift Card #{@order_item.sku}",@order,5)
      @item = @order_item.item
    end
    @order.reload

  end
  def update_order_items
    @order = initialize_order
  end
  
  def update_pos_display
    @order = initialize_order
    if @order.paid == 1 and not @current_user.is_technician? then
      @order = @current_user.get_new_order
    end
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
  
#   def refund_order
#     @order = Order.scopied.find_by_id(params[:id].to_s)
#     @order.toggle_refund(true, params[:pm])
#     @order.save
#     redirect_to order_path(@order)
#   end
  
  def customer_display
    @order = @current_vendor.orders.visible.find_by_id(params[:id])
    @order_items = @order.order_items.visible.order('id ASC')
    @report = @order.report
    render :layout => 'customer_display'
  end

#   def report
#     f, t = assign_from_to(params)
#     @from = f
#     @to = t
#     from2 = @from.beginning_of_day
#     to2 = @to.beginning_of_day + 1.day
#     @orders = Order.scopied.find(:all, :conditions => { :created_at => from2..to2, :paid => true })
#     @orders.reverse!
#     @taxes = TaxProfile.scopied.where( :hidden => 0)
#   end

#   def report_range
#     f, t = assign_from_to(params)
#     @from = f
#     @to = t
#     @from = @from.beginning_of_day
#     @to = @to.end_of_day
#     @vendor = GlobalData.vendor
#     @report = UserUserMethods.get_end_of_day_report(@from,@to,nil)
#   end

#   def report_day_range
#     f, t = assign_from_to(params)
#     @from = f
#     @to = t
#     from2 = @from.beginning_of_day
#     to2 = @to.beginning_of_day + 1.day
#     @taxes = TaxProfile.scopied.where( :hidden => 0)
#   end
  
  def receipts
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    @receipts = @current_vendor.receipts.where(["created_at between ? and ?", @from, @to])
    if params[:print] == "true" and params[:current_register_id] then
      @current_register = @current_vendor.current_registers.find_by_id(params[:current_register_id].to_s)
      vendor_printer = VendorPrinter.new :path => @current_register.thermal_printer
      print_engine = Escper::Printer.new('local', vendor_printer)
      print_engine.open
      
      @receipts.each do |r|
        contents = r.content
        bytes_written, content_written = print_engine.print(0, contents)
      end
      print_engine.close
    end
  end
  
  def print
    @order = @current_vendor.orders.visible.find_by_id(params[:id])
    @report = @order.report
    view = 'default'
    render "orders/invoices/#{view}/page"
  end
  
#   def order_reports
#     f, t = assign_from_to(params)
#     @from = f
#     @to = t
#     params[:limit] ||= 15
#     @limit = params[:limit].to_i - 1
#     
#     
#     @orders = Order.scopied.where({:paid => 1, :created_at => @from..@to})
#     
#     @reports = {
#         :items => {},
#         :categories => {},
#         :locations => {}
#     }
#     @orders.each do |o|
#       o.order_items.visible.each do |oi|
#         next if oi.item.nil?
#         key = oi.item.name + " (#{oi.price})"
#         cat_key = oi.get_category_name
#         loc_key = oi.get_location_name
#         
#         @reports[:items][key] ||= {:sku => '', :quantity_sold => 0.0, :cash_made => 0.0 }
#         @reports[:items][key][:quantity_sold] += oi.quantity
#         @reports[:items][key][:cash_made] += oi.total
#         @reports[:items][key][:sku] = oi.sku
#         
#         @reports[:categories][cat_key] ||= { :quantity_sold => 0.0, :cash_made => 0.0 }
#         
#         @reports[:categories][cat_key][:quantity_sold] += oi.quantity
#         @reports[:categories][cat_key][:cash_made] += oi.total
#         
#         @reports[:locations][loc_key] ||= { :quantity_sold => 0.0, :cash_made => 0.0 }
#         
#         @reports[:locations][loc_key][:quantity_sold] += oi.quantity
#         @reports[:locations][loc_key][:cash_made] += oi.total
#       end
#     end
#     
#     
#     
#     @categories_by_cash_made = @reports[:categories].sort_by { |k,v| v[:cash_made] }
#     @categories_by_quantity_sold = @reports[:categories].sort_by { |k,v| v[:quantity_sold] }
#     @locations_by_cash_made = @reports[:locations].sort_by { |k,v| v[:cash_made] }
#     @locations_by_quantity_sold = @reports[:locations].sort_by { |k,v| v[:quantity_sold] }
#     @items = @reports[:items].sort_by { |k,v| v[:quantity_sold] }
#     
#     view = SalorRetail::Application::CONFIGURATION[:reports][:style]
#     view ||= 'default'
#     render "orders/reports/#{view}/page"
#   end

  
  def clear
    if not @current_user.can(:clear_orders) then
      History.record(:failed_to_clear,@order,1)
      render 'update_pos_display' and return
    end
    
    @order = @current_vendor.orders.where(:paid => nil).find_by_id(params[:order_id])
    
    if @order then
      History.record("Destroying #{@order.order_items.visible.count} items",@order,1)
      
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
    # just to log into the production.log
  end

  private
 
#   
#   def currency(number,options={})
#     options.symbolize_keys!
#     defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
#     currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})
#     defaults[:negative_format] = "-" + options[:format] if options[:format]
#     options   = defaults.merge!(options)
#     unit      = I18n.t("number.currency.format.unit")
#     format    = I18n.t("number.currency.format.format")
#     puts  "Format is: " + format
#     if number.to_f < 0
#       format = options.delete(:negative_format)
#       number = number.respond_to?("abs") ? number.abs : number.sub(/^-/, '')
#     end
#     value = number_with_precision(number)
#     puts  "value is " + value
#     format.gsub(/%n/, value).gsub(/%u/, unit)
#   end
#   def number_with_precision(number, options = {})
#     options.symbolize_keys!
# 
#     number = begin
#       Float(number)
#     rescue ArgumentError, TypeError
#       if options[:raise]
#         raise InvalidNumberError, number
#       else
#         return number
#       end
#     end
# 
#     defaults           = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
#     precision_defaults = I18n.translate(:'number.precision.format', :locale => options[:locale], :default => {})
#     defaults           = defaults.merge(precision_defaults)
# 
#     options = options.reverse_merge(defaults)  # Allow the user to unset default values: Eg.: :significant => false
#     precision = 2
#     significant = options.delete :significant
#     strip_insignificant_zeros = options.delete :strip_insignificant_zeros
# 
#     if significant and precision > 0
#       if number == 0
#         digits, rounded_number = 1, 0
#       else
#         digits = (Math.log10(number.abs) + 1).floor
#         rounded_number = (BigDecimal.new(number.to_s) / BigDecimal.new((10 ** (digits - precision)).to_f.to_s)).round.to_f * 10 ** (digits - precision)
#         digits = (Math.log10(rounded_number.abs) + 1).floor # After rounding, the number of digits may have changed
#       end
#       precision = precision - digits
#       precision = precision > 0 ? precision : 0  #don't let it be negative
#     else
#       rounded_number = BigDecimal.new(number.to_s).round(precision).to_f
#     end
#     formatted_number = number_with_delimiter("%01.#{precision}f" % rounded_number, options)
#     return formatted_number
#   end
#   def number_with_delimiter(number, options = {})
#     options.symbolize_keys!
# 
#     begin
#       Float(number)
#     rescue ArgumentError, TypeError
#       if options[:raise]
#         raise InvalidNumberError, number
#       else
#         return number
#       end
#     end
# 
#     defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
#     options = options.reverse_merge(defaults)
# 
#     parts = number.to_s.split('.')
#     parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
#     return parts.join(options[:separator])
#   end
#   {END}
end
