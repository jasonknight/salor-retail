# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
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
      redirect_to vendors_path and return
    elsif check then
      user = Employee.login(params[:code]) 
      user = User.login(params[:code]) if not user
    else
      redirect_to :controller => :home, :action => :index, :notice => "Check failed" and return
    end

        
    if user then
      if check == 41 and not request.url.include? "salortrainer" then
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
      $User = user
      History.record("employee_sign_in",user,5)
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
          redirect_to vendors_path
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
    @employee = $User.get_employee(params[:id])
    respond_to do |format|
      if @employee.update_attributes(params[:employee])
        @employee.set_role_cache
        @employee.save
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
