# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class VendorsController < ApplicationController


  def csv
    @vendor = Vendor.find_by_token(params[:token])
    if @vendor then
      @items = Item.where(["vendor_id =? and hidden != 1",@vendor.id])
      @categories = Category.where(["vendor_id =? and hidden != 1",@vendor.id])
      @buttons = Button.where(["vendor_id =? and hidden != 1",@vendor.id]) if @vendor.salor_configuration.csv_buttons
      @discounts = Discount.where(["vendor_id =? and hidden IS FALSE OR hidden IS NULL",@vendor.id]) if @vendor.salor_configuration.csv_discounts
      @customers = Customer.where(["vendor_id =? and hidden != 1",@vendor.id]) if @vendor.salor_configuration.csv_customers
    end
    render :layout => false
  end
  
  def index
    @vendors = @current_company.vendors(params[:page])
  end

  def show
    if not check_license() then
      redirect_to :controller => "home", :action => "index" and return
    end
    @vendor = @current_user.vendor(params[:id])
  end

  # GET /vendors/new
  # GET /vendors/new.xml
  def new
    @vendor = Vendor.new
    @vendor.salor_configuration = SalorConfiguration.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vendor }
    end
  end

  # GET /vendors/1/edit
  def edit
    @vendor = Vendor.find(params[:id])
    if @vendor.salor_configuration.nil? then
      @vendor.salor_configuration = SalorConfiguration.new
    end
    
    if not @vendor.vendor_printers.any? then
      @vendor.vendor_printers.build
    end
  end

  # POST /vendors
  # POST /vendors.xml
  def create
    @vendor = Vendor.new(params[:vendor])

    respond_to do |format|
      if @vendor.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Vendor.model_name.human)) }
        format.xml  { render :xml => @vendor, :status => :created, :location => @vendor }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vendor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vendors/1
  # PUT /vendors/1.xml
  def update
    @vendor = @current_user.vendor(params[:id])
    
    respond_to do |format|
      if @vendor.update_attributes(params[:vendor])
        format.html { redirect_to :action => 'edit', :notice => 'Vendor was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vendor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vendors/1
  # DELETE /vendors/1.xml
  def destroy
    @vendor = @current_user.vendor(params[:id])
    @vendor.kill

    respond_to do |format|
      format.html { redirect_to(vendors_url) }
      format.xml  { head :ok }
    end
  end
  
  #
  def new_drawer_transaction
      @drawer_transaction = DrawerTransaction.new(params[:transaction])
      # Before we do any transaction, we need to know how much was in the drawer
      # at the time of the transaction for error checking purposes later, as
      # some users have had trouble remembering how they handled their drawer money.
      #
      # Normally, it is important to ensure that the total shown represents 100%
      # real, physically present money. You cannot half use Dts, you either track
      # everything with Dts, or you track nothing with them.
      @drawer_transaction.drawer_amount = @current_user.get_drawer.amount
      # Ideally, we don't allow a payout of more than is in the drawer.
      if @drawer_transaction.amount > @current_user.get_drawer.amount and @drawer_transaction.payout == true then
        @drawer_transaction.amount = @current_user.get_drawer.amount
      end
      if @drawer_transaction.amount < 0 then
         @drawer_transaction.amount *= -1
         @drawer_transaction.drop = false
         @drawer_transaction.payout = true
      end
      if params[:user_id] then
        if params[:user_id] == 'self' then
          @drawer_transaction.drawer_id = @current_user.get_drawer.id
          @drawer_transaction.user = @current_user
        else
          emp = User.scopied.find_by_id(params[:user_id])
          @drawer_transaction.drawer_id = emp.get_drawer.id
          @drawer_transaction.user = emp
        end
      else
        @drawer_transaction.drawer_id = @current_user.get_drawer.id
      end
      if @drawer_transaction.save then
        # @drawer_transaction.print if not @current_register.salor_printer == true
        if @drawer_transaction.drop then
          @drawer_transaction.user.get_drawer.update_attribute(:amount,@drawer_transaction.user.get_drawer.amount + @drawer_transaction.amount)
        elsif @drawer_transaction.payout then
          if @drawer_transaction.amount > @drawer_transaction.user.get_drawer.amount then
            GlobalErrors.append_fatal("system.errors.not_enough_in_drawer")
          else
            @drawer_transaction.user.get_drawer.update_attribute(:amount,@drawer_transaction.user.get_drawer.amount - @drawer_transaction.amount)
          end
        else
          GlobalErrors.append_fatal("system.errors.must_specify_drop_or_payout")
        end
        # Do this here - sweeping a different model!
      else
        raise "Failed to save..."
      end
    @current_user.get_drawer.reload
  end

  def open_cash_drawer
    @current_register.open_cash_drawer
    render :nothing => true
  end
  
  def render_open_cashdrawer
    render :text => "\x1D\x61\x01" + "\x1B\x70\x00\x30\x01 "
  end

  def render_drawer_transaction_receipt
    if params[:user_type] == 'User'
      @user = User.find_by_id(params[:user_id])
    else
      @user = User.find_by_id(params[:user_id])
    end
    @register = CashRegister.find_by_id(params[:current_register_id])
    @vendor = @register.vendor if @register
    render :nothing => true and return if @register.nil? or @vendor.nil? or @user.nil?

    @dt = DrawerTransaction.find_by_id(params[:id])
    GlobalData.vendor = @dt.user.get.vendor
    @current_user = @dt.user
    if not @dt then
      render :text => "Could not find drawer_transaction" and return
    end
    
    if @register.salor_printer
      render :text => Escper::Asciifier.new.process(@dt.escpos)
    else
      @dt.print
      render :nothing => true
    end
  end


  def render_end_of_day_receipt
    if params[:user_type] == 'User'
      @user = User.find_by_id(params[:user_id])
    else
      @user = User.find_by_id(params[:user_id])
    end
    @register = CashRegister.find_by_id(params[:current_register_id])
    @vendor = @register.vendor if @register
    #`espeak -s 50 -v en "#{ params[:current_register_id] }"`
    render :nothing => true and return if @register.nil? or @vendor.nil? or @user.nil?

    @from, @to = assign_from_to(params)
    @from = @from ? @from.beginning_of_day : DateTime.now.beginning_of_day
    @to = @to ? @to.end_of_day : @from.end_of_day

    @report = UserUserMethods.get_end_of_day_report(@from.beginning_of_day,@to.end_of_day,@user)

    template = File.read("#{Rails.root}/app/views/printr/end_of_day.prnt.erb")
    erb = ERB.new(template, 0, '>')
    text = erb.result(binding)
    Receipt.create(:ip => request.ip, :user_id => @user.id, :current_register_id => @register.id, :content => text)
    if @register.salor_printer
      render :text => Escper::Asciifier.new.process(text)
    else
      vendor_printer = VendorPrinter.new :path => @register.thermal_printer
      print_engine = Escper::Printer.new('local', vendor_printer)
      print_engine.open
      print_engine.print(0, text)
      print_engine.close
      render :nothing => true
    end
  end

  def end_day
    begin
      @order = initialize_order if @current_user.order_id
    rescue
    end
    if not GlobalErrors.any_fatal? then
      @current_user.end_day
      if @current_user.class == User then
        @current_user.update_attribute :is_technician, false
      end
      session[:user_id] = nil
      redirect_to :controller => :home, :action => :index
      @current_user = nil
    end
  end
  
  
  def edit_field_on_child
    if params[:field] == "front_end_change" then
      o = @current_vendor.order.find_by_id(params[:order_id])
      o.update_attribute :front_end_change, SalorBase.string_to_float(params[:value]) if o
      render :nothing => true and return
    end
    
    
    if allowed_klasses.include? params[:klass]
      kls = Kernel.const_get(params[:klass])
      if not params[:id] and params[:order_id] then
        params[:id] = params[:order_id]
      end
      
      @inst = kls.where(:vendor_id => @current_vendor, :id => params[:id])
      if @inst       
        if @inst.class == Order
          @order = @inst
        elsif @inst.class == OrderItem
          @order = @inst.order
        end
        
        # --- push notification to refresh the customer screen
        t = SalorRetail.tailor
        if t
          t.puts "CUSTOMERSCREENEVENT|#{@current_vendor.hash_id}|#{ @order.current_register.name }|#{ request.protocol }#{ request.host }:#{ request.port }/orders/#{ @order.id }/customer_display"
        end
        # ---
          

        if @inst.respond_to? params[:field]
#            puts  "### Inst responds_to field #{params[:field]}"
          if not @current_user.owns_this?(@inst) and not GlobalData.salor_user.is_technician? then
             puts  "### User doesn't own resource"
            raise I18n.t("views.errors.no_access_right")
          end
#           puts "## Locked stuff"
          if @inst.class == Order or @inst.class == OrderItem then
#              puts  "### Checking for locked ..."
            meth = "#{params[:field]}_is_locked"
            if @inst.respond_to? meth.to_sym then
#                puts  "### inst responds_to #{meth}"
              @inst.update_attribute(meth.to_sym,true)
              render :layout => false and return
            end
          end

          params[:value] = SalorBase.string_to_float(params[:value]) if ['quantity','price','base_price'].include? params[:field]
#            puts  " --- " + params[:value].to_s
          if kls == OrderItem then
            if params[:field] == 'price' and @inst.behavior == 'normal' and @inst.coupon_applied == false and @inst.is_buyback == false and @inst.order.buy_order == false then
#                puts  "### field is price"
              unless @inst.activated then
                # Takes into account ITEM rebate and ORDER rebate.
                # ORDER and ITEM totals are updated in DB and in instance vars for JS
                newval = params[:value].to_s.gsub(/[^\d\.]/,'').to_f.round(2)
                origttl = @inst.total
                @inst.rebate.nil? ? oi_rebate = 0 : oi_rebate = @inst.rebate
                @inst.price = newval
                @inst.calculate_total_with_rebate
                @inst.calculate_rebate_amount
                # Calculate OI tax, but update DB below instead
                @inst.calculate_tax(true)
                # Only include ORDER rebate in calculation if type = 'percent'
                @inst.order.rebate_type == 'fixed' ? order_rebate = 0 : order_rebate = @inst.order.rebate
                # NEW ORDER TOTAL =  OLD_ORDER_TOTAL - (OLD_OI_TOTAL - ORDER_REBATE) + NEW_OI_TOTAL_WITH_OI_REBATE - ORDER_REBATE_FOR_OI 
                @inst.order.total = @inst.order.total - (origttl - (origttl * (order_rebate / 100.0))) + @inst.total - @inst.calculate_oi_order_rebate
                # @inst.connection.execute("update order_items set total = #{@inst.total}, price = #{@inst.price}, tax = #{@inst.tax} where id = #{@inst.id}")
                @inst.save

                @inst.connection.execute("update `orders` set `total` = #{@inst.order.total} where `id` = #{@inst.order.id}")
                @inst.is_valid = true
                render :layout => false and return
              end
            elsif params[:field] == 'rebate' and @inst.behavior == 'normal' and @inst.coupon_applied == false and @inst.is_buyback == false and @inst.order.buy_order == false then
#                puts  "### field is rebate"
              # Takes into account ITEM rebate and ORDER rebate.
              # ORDER and ITEM totals are updated in DB and in instance vars for JS
              rebate = params[:value].gsub(',','.').to_f
              origttl = @inst.total
              @inst.calculate_total_with_rebate(rebate)
              @inst.calculate_rebate_amount
              # Calculate OI tax, but update DB below instead
              @inst.calculate_tax(true)
              # Only include ORDER rebate in calculation if type = 'percent'
              @inst.order.rebate_type == 'fixed' ? order_rebate = 0 : order_rebate = @inst.order.rebate
              # NEW ORDER TOTAL =  OLD_ORDER_TOTAL - (OLD_OI_TOTAL - ORDER_REBATE) + NEW_OI_TOTAL_WITH_OI_REBATE - ORDER_REBATE_FOR_OI 
              @inst.order.total = @inst.order.total - (origttl - (origttl * (order_rebate / 100.0))) + @inst.total - @inst.calculate_oi_order_rebate
              @inst.connection.execute("update `order_items` set total = #{@inst.total}, rebate = #{rebate}, rebate_amount = #{ @inst.rebate_amount }, tax = #{@inst.tax} where id = #{@inst.id}")
              @inst.connection.execute("update `orders` set `total` = #{@inst.order.total} where `id` = #{@inst.order.id}")
              @inst.is_valid = true
              @inst.rebate = rebate
              render :layout => false and return
            else
#                puts  "### Other OrderItem updates executing"
              # For all other OrderItem updates
              # puts  "### update(#{params[:field].to_sym},#{params[:value]})"
              if params[:field] == 'quantity' and params[:value] > @inst.quantity then
                @inst.update_attribute(params[:field].to_sym,params[:value])
                puts "### field being updated is quantity"
                @inst = Action.run(@inst,:add_to_order)
              else
                @inst.update_attribute(params[:field].to_sym,params[:value])
                @inst = Action.run(@inst,:add_to_order)
              end
              
              
              @inst.calculate_total
              @inst.order.update_self_and_save
              @inst.reload
              
              render :layout => false and return
            end
          end
 
          if kls == Order then
            puts "klass is Order"
            # Tax for order is calculated before payment
            if params[:field] == 'rebate' and false == true then

#               puts "Updating scotty on order"
              # ORDER rebate updating
              old_rebate = @inst.rebate
              newvalue = params[:value].gsub(',','.').to_f
              if @inst.rebate_type == 'percent' then
                # Add old % rebate back to order total
                @inst.total = @inst.total + ((@inst.total * (old_rebate / 100.0)) / (1 - (old_rebate / 100.0)))
                # Subtract new % rebate from order total
                @inst.total = @inst.total - (@inst.total * (newvalue / 100.0))
                @inst.connection.execute("update `orders` set `total` = #{@inst.total}, `rebate` = #{newvalue} where `id` = #{@inst.id}")
                @inst.rebate = newvalue
                render :layout => false and return
              else
                # Fixed rebate is easier: + old, - new
                @inst.total = @inst.total + old_rebate - newvalue
                @inst.connection.execute("update `orders` set `total` = #{@inst.total}, `rebate` = #{newvalue} where `id` = #{@inst.id}")
                @inst.rebate = newvalue
                render :layout => false and return
              end
            elsif params[:field] == "front_end_change" then
              @inst.front_end_change = params[:value]
            elsif params[:field] == 'rebate_type' then
              # Changing rebate type means recalculating ORDER total
              old_rebate = @inst.rebate
              old_rebate_type = @inst.rebate_type
              newvalue = params[:value]
              unless newvalue == old_rebate_type then
                if old_rebate_type == 'percent' then
                  # Add old % rebate back to order total
                  @inst.total = @inst.total + ((@inst.total * (old_rebate / 100.0)) / (1 - (old_rebate / 100.0)))
                  # Subtract fixed rebate
                  @inst.total -= old_rebate
                  @inst.connection.execute("update `orders` set `total` = #{@inst.total}, `rebate_type` = '#{newvalue}' where `id` = #{@inst.id}")
                  @inst.rebate_type = newvalue
                  render :layout => false and return
                else
                  # fixed rebate
                  @inst.total += old_rebate
                  @inst.total = @inst.total - (@inst.total * (old_rebate / 100.0))
                  @inst.connection.execute("update `orders` set `total` = #{@inst.total}, `rebate_type` = '#{newvalue}' where `id` = #{@inst.id}")
                  @inst.rebate_type = newvalue
                  render :layout => false and return
                end
              end
            else
              # For all other Order updates
              puts "Updating directly on order"
              @inst.update_attribute(params[:field].to_sym,params[:value])
              @inst.calculate_totals
              @inst.update_self_and_save
              render :layout => false and return
            end
          end
          # Else update attribute for other classes
          @inst.update_attribute(params[:field].to_sym,params[:value])
        else
          #raise "ModelKnowsNot"
        end # @inst.responds_to?
      else
        #raise "ModelNotFound"
      end #end klass.exists?
    else
      #raise "ModelNotAllowed!"
    end #end allowed_klass
    render :layout => false
  end

  def history
    @histories = History.order("created_at desc").page(params[:page]).per($Conf.pagination)
  end

  def toggle
    if allowed_klasses.include? params[:klass]
      kls = Kernel.const_get(params[:klass])
      if kls.exists? params[:model_id] then
        @inst = kls.find(params[:model_id])
        if @inst.respond_to? params[:field]
          if not @current_user.owns_this?(@inst) then
            raise I18n.t("views.errors.no_access_right")
          end
          @inst.send(params[:field].to_sym,params[:value])
        end # @inst.responds_to?
      else
        raise "RecordNotFound"
      end # klass.exists?
    end # allowed_klasses
    render(:nothing => true) and return if params[:field] == 'toggle_refund'
    @inst.reload
    render :layout => false
  end
  
  def export
    if params[:file] then
      manager = CsvManager.new(params[:file],"\t")
      if params[:do_what] == 'download' then
        output = manager.route(params)
        send_csv(output,params[:download_type] + '_Download') and return
      else
        output = manager.send params[:do_what]
        no = output[:successes].join "\n"
        no = no + "\n" + output[:errors].join("\n")
        send_csv(no,params[:do_what]) and return
      end
    end
  end

  def labels
    render :layout => false    
  end

  def logo
    @vendor = Vendor.find(params[:id])
    send_data @vendor.logo_image, :type => @vendor.logo_image_content_type, :filename => 'abc', :disposition => 'inline'
  end
  
  def logo_invoice
    @vendor = Vendor.find(params[:id])
    send_data @vendor.logo_invoice_image, :type => @vendor.logo_invoice_image_content_type, :filename => 'abc', :disposition => 'inline'
  end

  
  def display_logo
    @vendor = Vendor.find(params[:id])
    render :layout => 'customer_display'
  end
  
  def backup
    configpath = SalorRetail::Application::SR_DEBIAN_SITEID == 'none' ? 'config/database.yml' : "/etc/salor-retail/#{SalorRetail::Application::SR_DEBIAN_SITEID}/database.yml"
    dbconfig = YAML::load(File.open(configpath))
    mode = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
    username = dbconfig[mode]['username']
    password = dbconfig[mode]['password']
    database = dbconfig[mode]['database']
    `mysqldump -u #{username} -p#{password} #{database} | bzip2 -c > #{Rails.root}/tmp/backup-#{$Vendor.id}.sql.bz2`


    send_file("#{Rails.root}/tmp/backup-#{$Vendor.id}.sql.bz2",:type => :bzip,:disposition => "attachment",:filename => "backup-#{$Vendor.id}.sql.bz2")

  end


  private

  def send_csv(lines,name)
    ftype = 'tsv'
    send_data(lines, :filename => "#{name}_#{Time.now.year}#{Time.now.month}#{Time.now.day}-#{Time.now.hour}#{Time.now.min}.#{ftype}", :type => 'application-x/csv') and return
	end
	# {END}
end
