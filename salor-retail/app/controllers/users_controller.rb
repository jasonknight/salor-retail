# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class UsersController < ApplicationController 
  
  skip_before_filter :loadup
  
  def verify
    if params[:password] then
      emp = User.login(params[:password])
      if not emp then
        render :text => "NO" and return
      else
        render :json => {:username => emp.username, :id => emp.id} and return
      end
    end
  end
  
  def clockin
    if params[:password] then
      emp = User.login(params[:password])
      if not emp then
        render :text => "NO" and return
      else
        login = UserLogin.where(:user_id => emp.id).last
        if login and login.logout.nil? then
          render :text => "ALREADY" and return
        end
        emp.start_day
        render :json => {:username => emp.username, :id => emp.id} and return
      end
    end
  end
  
  def clockout
    if params[:password] then
      emp = User.login(params[:password])
      if not emp then
        render :text => "NO" and return
      else
        emp.end_day
        render :json => {:username => emp.username, :id => emp.id} and return
      end
    end
  end

  
  def login
    user = User.login(params[:code]) 
    if user then
      session[:user_id] = user.id
      session[:vendor_id] = user.vendor_id
      user.start_day
      redirect_to new_order_path
    else
      redirect_to home_index_path
    end
  end
  
  def destroy_login
    @user = User.find_by_id(params[:id].to_s)
    if @user and @user.vendor_id == @current_user.vendor_id then
      login = UserLogin.find_by_id(params[:login].to_s)
      if login.user_id == @user.id and @current_user.role_cache.include? 'manager' then
        login.destroy
      else
        raise "Ids Don't Match" + login.user.id.to_s + " ---- " + @current_user.role_cache
      end
    else
      redirect_to :action => :index and return
    end
    redirect_to :action => :show, :id => @user.id
  end
  # GET /users
  # GET /users.xml
  def index
    @users = $Vendor.users.scopied.order("created_at desc").page(params[:page]).per(25)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    f, t = assign_from_to(params)
    @from = f
    @to = t
    @user = User.find_by_id(params[:id])
    @user.make_valid
    add_breadcrumb @user.username,'user_path(@user,:vendor_id => params[:vendor_id])'
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = @current_user.get_user(params[:id])
    add_breadcrumb @user.username,'edit_user_path(@user,:vendor_id => params[:vendor_id])'
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    @user.make_valid
    respond_to do |format|
      if @user.save
        format.html { redirect_to(:action => 'new', :notice => I18n.t("views.notice.model_create", :model => User.model_name.human)) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = @current_user.get_user(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:user])
        @user.set_role_cache
        @user.save
        [:cache_drop, :application_js, :header_menu,:vendors_show].each do |c|
        end
        format.html { redirect_to :action => 'edit', :id => @user.id, :notice => 'User was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { redirect_to :action => 'edit', :id => @user.id, :notice => "User could not be saved." }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.scopied.find(params[:id])
    @user.kill

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end
  end
  private 
  def crumble
    @vendor = @current_user.vendor(@current_user.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.users"),'users_index_path(:vendor_id => params[:vendor_id])'
  end
end
