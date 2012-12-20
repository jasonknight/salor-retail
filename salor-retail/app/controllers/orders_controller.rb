# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
# {VOCABULARY} orders_item item_price oi_price customer_payments payments_type payments_method paying_agent agent_has_paid agent_will_pay_later gift_card_applies coupon_percentage coupon_updated gift_cards_used item_price_update item_discount_percentage cash_register_used cash_register_inc include_register_codes employee_vendor
class OrdersController < ApplicationController
# {START}
   before_filter :authify, :except => [:customer_display,:print, :print_receipt, :print_confirmed]
   before_filter :initialize_instance_variables, :except => [:customer_display,:add_item_ajax, :print_receipt, :print_confirmed]
   before_filter :check_role, :only => [:new_pos, :index, :show, :new, :edit, :create, :update, :destroy, :report_day], :except => [:print_receipt, :print_confirmed]
   before_filter :crumble, :except => [:customer_display,:print, :print_receipt, :print_confirmed]
   
   # TODO: Remove method offline since empty.
   def offline
   end

  # TODO: Remove method new_pos since apparanlty no longer used.
#    def new_pos
#       if not salor_user.meta.vendor_id then
#         redirect_to :controller => 'vendors', :notice => I18n.t("system.errors.must_choose_vendor") and return
#       end
#       if not salor_user.meta.cash_register_id then
#         redirect_to :controller => 'cash_registers', :notice => I18n.t("system.errors.must_choose_register") and return
#       end
#       #if salor_user.get_drawer.amount <= 0 then
#       #  GlobalErrors.append("system.errors.must_cash_drop")
#       #end
#       @order = initialize_order
# 
#       add_breadcrumb @cash_register.name,'cash_register_path(@cash_register,:vendor_id => params[:vendor_id])'
#       add_breadcrumb t("menu.order") + "#" + @order.id.to_s,'new_order_path(:vendor_id => salor_user.meta.vendor_id)'
#       respond_to do |format|
#         format.html {render :layout => "application"}
#         format.xml  { render :xml => @order }
#       end
#    end

   
  def new_from_proforma
    @proforma = Order.scopied.find_by_id(params[:order_id]) #initialize_order
    @order = Order.new
    @order.attributes = @proforma.attributes
    @order.save
    @proforma.order_items.each do |oi|
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
    @order.update_self_and_save
    redirect_to "/orders/new?order_id=#{@order.id}"
  end
  def index
    @orders = salor_user.get_orders

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.xml
  def show
    @order = Order.scopied.find_by_id(params[:id])
    add_breadcrumb t("menu.order") + "#" + @order.id.to_s,'order_path(@order,:vendor_id => salor_user.meta.vendor_id)'
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @order }
    end
  end

  def new
    if not salor_user or not salor_user.meta.vendor_id then
      redirect_to :controller => 'vendors', :notice => I18n.t("system.errors.must_choose_vendor") and return
    end
    if not salor_user.meta.cash_register_id then
      redirect_to :controller => 'cash_registers', :notice => I18n.t("system.errors.must_choose_register") and return
    end
    
    $User.auto_drop
    
    @order = initialize_order
    if @order.paid == 1 and not $User.is_technician? then
      @order = $User.get_new_order
    end
    if @order.order_items.visible.any? then
      @order.update_self_and_save
    end
    add_breadcrumb @cash_register.name,'cash_register_path(@cash_register,:vendor_id => params[:vendor_id])'
    add_breadcrumb t("menu.order"),'new_order_path(:vendor_id => salor_user.meta.vendor_id)'
    @button_categories = Category.where(:button_category => true).order(:position)

  end

  # GET /orders/1/edit
  def edit
    @order = Order.scopied.find_by_id(params[:id])
    if @order.paid == 1 and not $User.is_technician? then
      redirect_to :action => :new, :notice => I18n.t("system.errors.cannot_edit_completed_order") and return
    end
    if @order and (not @order.paid == 1 or $User.is_technician?) then
      session[:prev_order_id] = salor_user.meta.order_id
      $User.meta.update_attributes(:order_id => @order.id)
      @order.update_attributes(:cash_register_id => $User.get_meta.cash_register_id)
    end
    redirect_to :action => :new, :order_id => @order.id
  end
  def swap
    @order = Order.scopied.find_by_id(params[:id])
    if @order and (not @order.paid == 1 or $User.is_technician?) then
      GlobalData.salor_user.meta.update_attribute(:order_id,@order.id)
    end
    redirect_to :action => "new"
  end
  # POST /orders
  # POST /orders.xml
  def create
    @order = Order.find(params[:id])
    respond_to do |format|
      if @order.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Order.model_name.human)) }
        format.xml  { render :xml => @order, :status => :created, :location => @order }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.xml
  def update
    @order = Order.find(params[:id])
    if @order.paid == 1 and not $User.is_technician? then
      GlobalErrors.append("system.errors.cannot_edit_completed_order",@order)
    end
    respond_to do |format|
      if (not @order.paid == 1 or $User.is_technician?) and @order.update_attributes(params[:order])
        format.html { redirect_to(@order, :notice => 'Order was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.xml
  def destroy
    @order = Order.by_vendor.find(params[:id])
    @order.kill
    respond_to do |format|
      format.html { redirect_to(orders_url) }
      format.xml  { head :ok }
    end
  end
  
  def recently_tagged
    @orders = Order.where("tag != '' and tag IS NOT NULL").scopied.order("id DESC").limit(5)
    render :text => @orders.to_json
  end
  def prev_order
    salor_user.meta.order_id = session[:prev_order_id]
    session[:prev_order_id] = nil
    redirect_to :action => :new
  end

  def connect_loyalty_card
    @order = initialize_order
    @loyalty_card = LoyaltyCard.scopied.find_by_sku(params[:sku])
    if @loyalty_card then
      @order.customer = @loyalty_card.customer
      @order.tag = @order.customer.full_name
      @order.save
    end
  end

  def add_item_ajax
#     puts "!!! add_item_ajax"
    @error = nil
    @order = initialize_order
    if @order.paid == 1 and not $User.is_technician? then
      @order = $User.get_new_order 
      @item = Item.get_by_code(params[:sku])
      @order_item = @order.add_item(@item)
      @order.update_self_and_save
      @order_item.reload
      render and return
    end
    @order_item = @order.order_items.visible.where(['(no_inc IS NULL or no_inc = 0) AND sku = ? AND behavior != ?', params[:sku], 'coupon']).first
    # We cannot sell multiples of gift cards.
    if @order_item and @order_item.behavior == 'gift_card' then
      flash[:notice] = I18n.t("system.errors.insufficient_quantity_on_item", :sku => @order_item.sku)
      render :action => :update_pos_display and return
    end
    unless @order_item.nil? then
      unless @order_item.activated or @order_item.is_buyback then
       #raise ""
        @order_item.quantity += 1
        @order_item.save
        @order_item.order.update_self_and_save
        @order = @order_item.order
        @order_item.reload
        render and return
      end
    end
    @item = Item.get_by_code(params[:sku])
#     puts "!!! returned Item: #{@item.sku}"
    if @item.class == Item and @item.activated == true and @item.behavior == 'gift_card' and @item.amount_remaining <= 0 then
      flash[:notice] = I18n.t("system.errors.gift_card_empty")
      render :action => :update_pos_display and return
    end
    if @item.class == Item and @item.behavior == 'gift_card' and @item.sku == "G000000000000" then
      zero_tax_profile = TaxProfile.scopied.where(:value => 0).first
      if zero_tax_profile.nil? then
        zero_tax_profile = TaxProfile.scopied.where(:default => 1).first
      end
      raise "NoTaxProfileFound" if zero_tax_profile.nil?
      timecode = Time.now.strftime('%y%m%d%H%M%S')
      @item = Item.create(:sku => "G#{timecode}", :vendor_id => $Vendor.id, :tax_profile_id => zero_tax_profile.id, :name => "Auto Giftcard #{timecode}", :must_change_price => true, :behavior => 'gift_card')
      @item.item_type = ItemType.find_by_behavior :gift_card
      @item.behavior = 'gift_card'
      @item.save
    end
    if @item.class == Item and @item.behavior == 'coupon' and not @order.order_items.visible.where(:sku => @item.coupon_applies).any? then
      flash[:notice] = I18n.t("system.errors.coupon_not_enough_items")
      render :action => :update_pos_display and return
    end
    if @item.class == LoyaltyCard then
      @loyalty_card = @item
      @order.customer = @loyalty_card.customer
      if @order.save then
        render :action => "connect_loyalty_card" and return
      else
        flash[:notice] = "Customer NIL?"
        render :action => :update_pos_display and return
      end
    end
#     puts "!!! Adding item to order"
    @order_item = @order.add_item(@item)
    if @order_item.id.nil? then
      GlobalErrors.append("system.errors.item_cannot_be_added")
      render :action => "errors" and return
    end
    @order_item.reload
    if @order_item.behavior != 'normal' then
      # Recalc all if item added is not normal
#       puts "!!! item behavior is #{@order_item.behavior}"
      @order.update_self_and_save
    else
      unless @order_item.activated or @order_item.item.is_gs1 then
        @order = @order_item.order
        @order.update_self_and_save
        @order_item.calculate_total
      end
    end
    if @item.base_price.zero? and not @item.is_gs1 and not @item.must_change_price and not @item.default_buyback
      GlobalErrors.append("system.errors.item_price_is_zero")
      SalorBase.beep(1500, 100, 3, 10)
    end
  end

  #
  def delete_order_item
    @order = initialize_order
    if not $User.can(:destroy_order_items) then
      GlobalErrors.append("system.errors.no_role",$User)
      @include_order_items = true
      render :action => :update_pos_display and return
    end

    if OrderItem.exists?(params[:id])
      @order_item = OrderItem.find(params[:id])
      @roi = @order.remove_order_item(@order_item)
      @order.update_self_and_save
      if @roi then
        @roi.calculate_total
        @roi.reload
      end
      @order.reload
    end
  end

  def print_receipt
    if params[:user_type] == 'User'
      @user = User.find_by_id(params[:user_id])
    else
      @user = Employee.find_by_id(params[:user_id])
    end
    @register = CashRegister.find_by_id(params[:cash_register_id])
    if @register then
      @vendor = @register.vendor 
    end
    render :nothing => true and return if @register.nil? or @vendor.nil? or @user.nil?

    @order = Order.find_by_id(params[:order_id])
    if not @order then
      render :text => "No Order Found" and return
    end
    
    if @register.salor_printer
      @report = @order.get_report
      contents = @order.escpos_receipt(@report)
      output = Escper::Printer.merge_texts(contents[:text], contents[:raw_insertations])
      if params[:download] then
        send_data(output, {:filename => 'salor.bill'})
      else
        render :text => output and return
      end
    else
      if is_mac? then
        @report = @order.get_report
        contents = @order.escpos_receipt(@report)
        output = Escper::Printer.merge_texts(contents[:text], contents[:raw_insertations])
        File.open("/tmp/" + @register.thermal_printer,'wb') { |f| f.write output }
        `lp -d #{@register.thermal_printer} /tmp/#{@register.thermal_printer}`
        render :nothing => true and return
      else
        @order.print
      end
      render :nothing => true and return
    end
  end

  # due to a report of a client, just rendering the template is not enough for putting "copy/duplicate" on the receipt. so, let salor-bin confirm if bytes were actually sent to a file.
  def print_confirmed
    o = Order.find_by_id params[:order_id]
    o.update_attribute :was_printed, true if o
    render :nothing => true
  end

  # {START}
  def show_payment_ajax
    # Recalculate everything and then show Payment Popup
    @order = initialize_order
    # MF: speedy version of calculate_totals is completely commented out in order.rb, so that would explain why in case of a racing condition (e.g. where 2 items are scanned and the first ajax request is handled AFTER the second ajax request due to passenger instance queue) the order total was not recalculated and was therefore missing one item.
    # I changed below to "false", which means, every time the "complete" button is pressed, it will update the order total according to the items. In dev mode, it is still speedy, so I think it's safe for the live systems. This makes screen masking unnecessary and passenger instances can now be more than 1 again.
    @order.calculate_totals(false)
    @order.save!
  end
  def last_five_orders
    @text = render_to_string('shared/_last_five_orders',:layout => false)
    render :text => @text
  end
  def bancomat
    if params[:msg] then
        nm = JSON.parse(params[:msg]) 
        @p = PaylifeStructs.new(:sa => nm['sa'],:ind => nm['ind'],:struct => CGI::unescape(nm['msg']), :json => params[:msg])
        @p.set_model_owner
        if not @p.save then
          render :text => "alert('Saving Struct Failed!!');" and return
        end
    end
    render :nothing => true
  end
  def complete_order_ajax
    @order = initialize_order
    @old_order = @order
    # Here we check to see if there are any items on the order,
    # if there aren't, then it simply hides the popup. This is a bit
    # of a hack for cigarman who sometimes accidentally presses complete order
    # twice. Because of the recalculate change magic, it's difficult to know
    # in javascript if an order is completable or not.
    
    if not @order.order_items.visible.any? then
      
      render :js => "complete_order_hide(); " and return
    end
    
       
    #if GlobalData.salor_user.get_drawer.amount <= 0 then
    #  GlobalErrors.append_fatal("system.errors.must_cash_drop")
    #end
    
    if @order.total > 0 or @order.order_items.visible.any? and not GlobalErrors.any_fatal? then
      payment_methods_array = [] # We need to do some checks on the payment
      # methods, so we put them into an array before saving them and the order
      # This is kind of a validator, but we need to do it here for right now...
      payment_methods_total = 0.0
      payment_methods_seen = [] # In case they use the same internal type for two different payment_methods.
      PaymentMethod.types_list.each do |pmt|
        pt = pmt[1]
        next if payment_methods_seen.include? pt
        payment_methods_seen << pt
        if params[pt.to_sym] and not params[pt.to_sym].blank? and not SalorBase.string_to_float(params[pt.to_sym]) == 0 then
          pm = PaymentMethod.new(:name => pmt[0],:internal_type => pt, :amount => SalorBase.string_to_float(params[pt.to_sym]))
          if pm.amount > @order.total then
            # puts  "## Entering Sanity Check"
            sanity_check = pm.amount - @order.total
            # puts  "#{sanity_check}"
            if sanity_check > 500 then
              GlobalErrors.append_fatal("system.errors.sanity_check")
              render :action => :update_pos_display and return
            end
          end
          payment_methods_total += pm.amount
          pm.order_id = @order.id
          payment_methods_array << pm
        end
      end
      # Now we check the payment_methods_total to make sure that it matches
      # what we think the order.total should be
      @order.reload
      
      if payment_methods_total.round(2) < @order.total.round(2) and @order.is_proforma == false then
        GlobalErrors.append_fatal("system.errors.sanity_check")
        # update_pos_display should update the interface to show
        # the correct total, this was the bug found by CigarMan
        render :action => :update_pos_display and return
      else
        payment_methods_array.each {|pm| pm.save} # otherwise, we save them
      end
      if @order.is_proforma == true then
        @order.complete
        render :js => " window.location = '/orders/#{@order.id}/print'; " and return
      end
      params[:print].nil? ? print = 'true' : print = params[:print].to_s
      # Receipt printing moved into Order.rb, line 497
      @order.complete
      atomize(ISDIR, 'cash_drop')
      GlobalData.salor_user.meta.order_id = nil
      @order = GlobalData.salor_user.get_new_order
    end
  end
  def new_order_ajax
    GlobalData.salor_user.meta.order_id = nil
    @order = initialize_order
    flash[:notice] = I18n.t("views.notice.new_order")
  end
  def activate_gift_card
    @error = nil
    @order = initialize_order
    @order_item = @order.activate_gift_card(params[:id],params[:amount])
    if not @order_item then
      @error = true
    else
      @item = @order_item.item
    end
    @order.reload
    @order.update_self_and_save
  end
  def update_order_items
    @order = initialize_order
  end
  def update_pos_display
    @order = initialize_order
    if @order.paid == 1 and not $User.is_technician? then
      @order = GlobalData.salor_user.get_new_order
    end
  end
  def split_order_item
    @oi = OrderItem.find_by_id(params[:id])
    if @oi then
      noi = OrderItem.new(@oi.attributes)
      new_quantity = @oi.quantity - 1
      new_total = @oi.price * new_quantity
      noi.order_id = @oi.order_id
      noi.save
      OrderItem.connection.execute("update order_items set quantity = '#{new_quantity}', total = '#{new_total}' where id = #{@oi.id}") 
      OrderItem.connection.execute("update order_items set quantity = '#{1}', total = '#{@oi.price}', price = '#{@oi.price}' where id = #{noi.id}")
    end
    redirect_to "/orders/#{@oi.order.id}"
  end
  def refund_item
    @oi = OrderItem.scopied.find_by_id(params[:id])
    x = @oi.toggle_refund(true, params[:pm])
    if x == -1 then
      flash[:notice] = I18n.t("system.errors.not_enough_in_drawer")
    end
    if x == false then
      flash[:notice] = I18n.t("system.errors.unspecified_error")
    end
    @oi.save
    redirect_to request.referer
    
  end
  def refund_order
    @order = Order.scopied.find_by_id(params[:id])
    @order.toggle_refund(true, params[:pm])
    @order.save
    redirect_to order_path(@order)
  end
  def customer_display
    @order = Order.find_by_id(params[:id])
    GlobalData.salor_user = @order.get_user
    $User = @order.get_user
    @vendor = Vendor.find(@order.vendor_id)
    $Conf = @vendor.salor_configuration
    @order_items = @order.order_items.visible.order('id ASC')
    @report = @order.get_report
    if @order_items
    puts "### Order items are present."
      render :layout => 'customer_display', :nothing => :true
    else
      render :layout => 'customer_display'
    end
  end

  def report
    f, t = assign_from_to(params)
    @from = f
    @to = t
    from2 = @from.beginning_of_day
    to2 = @to.beginning_of_day + 1.day
    @orders = Order.scopied.find(:all, :conditions => { :created_at => from2..to2, :paid => true })
    @orders.reverse!
    @taxes = TaxProfile.scopied.where( :hidden => 0)
  end

  def report_range
    #@from, @to = assign_from_to(params)
    #from2 = @from.beginning_of_day
    #to2 = @to.beginning_of_day + 1.day
    #@orders = Order.scopied.find(:all, :conditions => { :created_at => from2..to2, :paid => true })
    #@orders.reverse!
    #@taxes = TaxProfile.scopied.where( :hidden => 0)
    f, t = assign_from_to(params)
    @from = f
    @to = t
    @from = @from.beginning_of_day
    @to = @to.end_of_day
    @vendor = GlobalData.vendor
    @report = UserEmployeeMethods.get_end_of_day_report(@from,@to,nil)
  end

  def report_day
    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day
    @vendor = GlobalData.vendor
    @employees = @vendor.employees.where(:hidden => 0)
    @employee = Employee.scopied.find_by_id(params[:employee_id])
    @report = UserEmployeeMethods.get_end_of_day_report(@from,@to,@employee)
  end

  def report_day_range
    f, t = assign_from_to(params)
    @from = f
    @to = t
    from2 = @from.beginning_of_day
    to2 = @to.beginning_of_day + 1.day
    @taxes = TaxProfile.scopied.where( :hidden => 0)
  end

  def print
    @order = Order.scopied.find_by_id(params[:id])
    GlobalData.salor_user = @order.user if @order.user
    GlobalData.salor_user = @order.employee if @order.employee
    $User = @order.employee
    $Conf = @order.vendor.salor_configuration
    @vendor = @order.vendor
    @report = @order.get_report
    @invoice_note = InvoiceNote.scopied.where(:origin_country_id => @order.origin_country_id, :destination_country_id => @order.destination_country_id, :sale_type_id => @order.sale_type_id).first
    locale = params[:locale]
    locale ||= I18n.locale
    if locale
      tmp = InvoiceBlurb.where(:lang =>locale, :vendor_id => $User.vendor_id, :is_header => true)
      if tmp.first then
        @invoice_blurb_header = tmp.first.body
      end
      tmp = InvoiceBlurb.where(:lang => locale, :vendor_id => $User.vendor_id).where('is_header IS NOT TRUE')
      if tmp.first then
        @invoice_blurb_footer = tmp.first.body
      end
    end
    @invoice_blurb_header ||= @vendor.salor_configuration.invoice_blurb
    @invoice_blurb_footer ||= @vendor.salor_configuration.invoice_blurb_footer
    view = SalorRetail::Application::CONFIGURATION[:invoice_style]
    view ||= 'default'
    render "orders/invoices/#{view}/page"
  end
  #
  def order_reports
    f, t = assign_from_to(params)
    @from = f
    @to = t
    params[:limit] ||= 15
    @limit = params[:limit].to_i - 1
    
    
    @orders = Order.scopied.where({:paid => 1, :created_at => @from..@to})
    
    @reports = {
        :items => {},
        :categories => {},
        :locations => {}
    }
    @orders.each do |o|
      o.order_items.visible.each do |oi|
        next if oi.item.nil?
        key = oi.item.name + " (#{oi.price})"
        cat_key = oi.get_category_name
        loc_key = oi.get_location_name
        
        @reports[:items][key] ||= {:sku => '', :quantity_sold => 0.0, :cash_made => 0.0 }
        @reports[:items][key][:quantity_sold] += oi.quantity
        @reports[:items][key][:cash_made] += oi.total
        @reports[:items][key][:sku] = oi.sku
        
        @reports[:categories][cat_key] ||= { :quantity_sold => 0.0, :cash_made => 0.0 }
        
        @reports[:categories][cat_key][:quantity_sold] += oi.quantity
        @reports[:categories][cat_key][:cash_made] += oi.total
        
        @reports[:locations][loc_key] ||= { :quantity_sold => 0.0, :cash_made => 0.0 }
        
        @reports[:locations][loc_key][:quantity_sold] += oi.quantity
        @reports[:locations][loc_key][:cash_made] += oi.total
      end
    end
    
    
    
    @categories_by_cash_made = @reports[:categories].sort_by { |k,v| v[:cash_made] }
    @categories_by_quantity_sold = @reports[:categories].sort_by { |k,v| v[:quantity_sold] }
    @locations_by_cash_made = @reports[:locations].sort_by { |k,v| v[:cash_made] }
    @locations_by_quantity_sold = @reports[:locations].sort_by { |k,v| v[:quantity_sold] }
    @items = @reports[:items].sort_by { |k,v| v[:quantity_sold] }
    
    view = SalorRetail::Application::CONFIGURATION[:reports][:style]
    view ||= 'default'
    render "orders/reports/#{view}/page"
  end
  #
  def remove_payment_method
    if GlobalData.salor_user.is_technician? then
      @order = Order.find(params[:id])
      if @order then
        @order.payment_methods.find(params[:pid]).destroy
      end
    end
  end
  def clear
    @order = initialize_order
    if not GlobalData.salor_user.can(:clear_orders) then
      GlobalErrors.append_fatal("system.errors.no_role",@order,{})
      render :action => :update_pos_display and return
    end
    if not @order.paid then
      @order.order_items.visible.each do |oi|
        oi.destroy
      end
      @order.customer_id = nil
      @order.tag = 'NotSet'
      @order.subtotal = 0
      @order.total = 0
      @order.tax = 0
      @order.update_self_and_save
    else
      GlobalErrors.append_fatal("system.errors.no_role",@order,{})
      render :action => :update_pos_display and return
    end
  end

  private
  def crumble
    return if not salor_user
    @vendor = salor_user.get_vendor(salor_user.meta.vendor_id) if @vendor.nil?
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.orders"),'orders_path(:vendor_id => params[:vendor_id])'
  end
  def currency(number,options={})
    options.symbolize_keys!
    defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})
    defaults[:negative_format] = "-" + options[:format] if options[:format]
    options   = defaults.merge!(options)
    unit      = I18n.t("number.currency.format.unit")
    format    = I18n.t("number.currency.format.format")
    # puts  "Format is: " + format
    if number.to_f < 0
      format = options.delete(:negative_format)
      number = number.respond_to?("abs") ? number.abs : number.sub(/^-/, '')
    end
    value = number_with_precision(number)
    # puts  "value is " + value
    format.gsub(/%n/, value).gsub(/%u/, unit)
  end
  def number_with_precision(number, options = {})
    options.symbolize_keys!

    number = begin
      Float(number)
    rescue ArgumentError, TypeError
      if options[:raise]
        raise InvalidNumberError, number
      else
        return number
      end
    end

    defaults           = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    precision_defaults = I18n.translate(:'number.precision.format', :locale => options[:locale], :default => {})
    defaults           = defaults.merge(precision_defaults)

    options = options.reverse_merge(defaults)  # Allow the user to unset default values: Eg.: :significant => false
    precision = 2
    significant = options.delete :significant
    strip_insignificant_zeros = options.delete :strip_insignificant_zeros

    if significant and precision > 0
      if number == 0
        digits, rounded_number = 1, 0
      else
        digits = (Math.log10(number.abs) + 1).floor
        rounded_number = (BigDecimal.new(number.to_s) / BigDecimal.new((10 ** (digits - precision)).to_f.to_s)).round.to_f * 10 ** (digits - precision)
        digits = (Math.log10(rounded_number.abs) + 1).floor # After rounding, the number of digits may have changed
      end
      precision = precision - digits
      precision = precision > 0 ? precision : 0  #don't let it be negative
    else
      rounded_number = BigDecimal.new(number.to_s).round(precision).to_f
    end
    formatted_number = number_with_delimiter("%01.#{precision}f" % rounded_number, options)
    return formatted_number
  end
  def number_with_delimiter(number, options = {})
    options.symbolize_keys!

    begin
      Float(number)
    rescue ArgumentError, TypeError
      if options[:raise]
        raise InvalidNumberError, number
      else
        return number
      end
    end

    defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    options = options.reverse_merge(defaults)

    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
    return parts.join(options[:separator])
  end
  # {END}
end
