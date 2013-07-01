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
    @vendor = @current_company.vendors.visible.find_by_id(params[:id])
  end

  def new
    @vendor = Vendor.new
  end

  def edit
    @vendor = @current_company.vendors.visible.find_by_id(params[:id])
  end

  def create
    @vendor = Vendor.new(params[:vendor])
    @vendor.company = @current_company
    if @vendor.save
      redirect_to vendors_path
    else
      render :new
    end
  end


  def update
    @vendor = @current_company.vendors.visible.find_by_id(params[:id])
    if @vendor.update_attributes(params[:vendor])
      redirect_to vendors_path
    else
      render :edit
    end
  end


  def new_drawer_transaction
      @drawer_transaction = DrawerTransaction.new(params[:transaction])
      @drawer_transaction.drawer_amount = @current_user.get_drawer.amount
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
          else
            @drawer_transaction.user.get_drawer.update_attribute(:amount,@drawer_transaction.user.get_drawer.amount - @drawer_transaction.amount)
          end
        else
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
    @current_user.end_day
    session[:user_id] = session[:vendor_id] = session[:company_id] = nil
    redirect_to home_index_path
  end
  
  def edit_field_on_child
    klass = params[:klass].constantize
    inst = klass.where(:vendor_id => @current_vendor).find_by_id(params[:id])
      
    if inst.class == Order
      @order = inst
    elsif inst.class == OrderItem
      @order = inst.order
    end
        
    # --- push notification to refresh the customer screen
    t = SalorRetail.tailor
    if @order and t
      t.puts "CUSTOMERSCREENEVENT|#{@current_vendor.hash_id}|#{ @order.cash_register.name }|#{ request.protocol }#{ request.host }:#{ request.port }/orders/#{ @order.id }/customer_display"
    end
    # ---

    #value = SalorBase.string_to_float(params[:value])
    value = params[:value]
    if inst.respond_to?("#{ params[:field] }=".to_sym)
      inst.send("#{ params[:field] }=", value)
      inst.save
    else
      raise "VendorsController#edit_field_on_child: #{ klass } does not respond well to setter method #{ params[:field] }!"
    end
    
    if inst.class == OrderItem
      inst.calculate_totals
      @order.calculate_totals
      render 'orders/update_pos_display'
    elsif inst.class == Order
      inst.calculate_totals
      render 'orders/update_pos_display'
    else
      render :nothing => true
    end
  end

  def history
    @histories = History.order("created_at desc").page(params[:page]).per($Conf.pagination)
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
