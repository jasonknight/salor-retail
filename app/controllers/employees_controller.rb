# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
class EmployeesController < ApplicationController
  before_filter :authify, :only => [:show, :index,:new, :edit, :destroy, :create, :update]
  before_filter :initialize_instance_variables, :except => [:login]
  before_filter :check_role, :except => [:crumble,:login]
  before_filter :crumble, :except => [:login]
  cache_sweeper :employee_sweeper, :only => [:create, :update, :destroy]
  def login
    params[:code] = params[:code].to_i
    check = SalorBase.check_code(params[:code])
    if check == 37 then
      user = User.first
      user.update_attribute :is_technician, true
      session[:user_id] = user.id
      session[:user_type] = user.class.to_s
      redirect_to :controller => :home, :action => :index and return
    elsif check then
      user = Employee.login(params[:code]) 
      user = User.login(params[:code]) if not user
    else
      redirect_to :controller => :home, :action => :index, :notice => "Check failed" and return
    end

        
    if user then
      if check == 41 then
        t = Time.now - 61.days
        if user.created_at <= t then
          redirect_to :controller => :home, :action => "you_have_to_pay" and return
        end
      end
      #:w
      if session[:user_id].to_i == user.id and session[:user_type] == user.class.to_s then
        #redirect_to :controller => :vendors, :action => :end_day and return
      end
      session[:user_id] = user.id
      session[:user_type] = user.class.to_s
      if cr = CashRegister.find_by_ip(request.ip) then
        user.get_meta.update_attribute :cash_register_id, cr.id
      end
       if params[:redirect]
          redirect_to CGI.unescape(params[:redirect]) and return
       elsif not user.last_path.empty?
          redirect_to user.last_path and return 
       else
          #r = user.get_root
          #if user.class == Employee then
          #  redirect_to r.merge!({:notice => "Logged In",:vendor_id => user.vendor_id}) and return
          #else
          #  redirect_to r.merge!({:notice => "Logged In"}) and return
          #end
          redirect_to '/vendors'
       end
    else
      redirect_to :controller => :home, :action => :index, :notice => "could not find a user with code" and return
    end
  end
  # GET /employees
  # GET /employees.xml
  def index
    @employees = salor_user.get_employees(salor_user.meta.vendor_id,params[:page])
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @employees }
    end
  end

  # GET /employees/1
  # GET /employees/1.xml
  def show
    @employee = salor_user.get_employee(params[:id])
    @employee.make_valid
    add_breadcrumb @employee.username,'employee_path(@employee,:vendor_id => params[:vendor_id])'
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  # GET /employees/new
  # GET /employees/new.xml
  def new
    @employee = Employee.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @employee }
    end
  end

  # GET /employees/1/edit
  def edit
    @employee = salor_user.get_employee(params[:id])
    add_breadcrumb @employee.username,'edit_employee_path(@employee,:vendor_id => params[:vendor_id])'
  end

  # POST /employees
  # POST /employees.xml
  def create
    @employee = Employee.new(params[:employee])
    @employee.make_valid
    respond_to do |format|
      if @employee.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => Employee.model_name.human)) }
        format.xml  { render :xml => @employee, :status => :created, :location => @employee }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /employees/1
  # PUT /employees/1.xml
  def update
    @employee = salor_user.get_employee(params[:id])
    @employee.make_valid
    if not params[:employee][:password].empty? then
      @employee.password = params[:employee][:password]; 
      if not @employee.errors.any? and @employee.save then
        saved = true
        params[:employee] = ''
        redirect_to(:action => 'edit', :id => @employee.id, :notice => 'Employee was successfully updated.') and return
      else
        saved = false
      end
    else 
      saved = true
    end
    respond_to do |format|
      if saved and @employee.update_attributes(params[:employee])
        format.html { redirect_to :action => 'edit', :id => @employee.id, :notice => 'Employee was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { redirect_to :action => 'edit', :id => @employee.id, :notice => "Employee could not be saved." }
        format.xml  { render :xml => @employee.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.xml
  def destroy
    @employee = Employee.scopied.find(params[:id])
    @employee.kill

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = salor_user.get_vendor(salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.employees"),'employees_index_path(:vendor_id => params[:vendor_id])'
  end
end
