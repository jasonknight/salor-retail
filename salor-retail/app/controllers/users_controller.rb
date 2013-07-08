# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class UsersController < ApplicationController
  
  skip_before_filter :loadup, :only => :login
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
      u = User.login(params[:password])
      if not u then
        render :text => "NO" and return
      else
        login = UserLogin.where(:user_id => u.id).last
        if login and login.logout.nil? then
          render :text => "ALREADY" and return
        end
        u.start_day
        render :json => {:username => u.username, :id => u.id} and return
      end
    end
  end
  
  def clockout
    if params[:password] then
      u = User.login(params[:password])
      if not u then
        render :text => "NO" and return
      else
        u.end_day
        render :json => {:username => u.username, :id => u.id} and return
      end
    end
  end

  
  def login
    user = User.login(params[:code]) 
    if user then
      session[:user_id] = user.id
      session[:vendor_id] = user.vendor_id
      session[:company_id] = user.company_id
      user.start_day
      redirect_to new_order_path
    else
      redirect_to home_index_path
    end
  end
  
  def destroy_login
    @user = @current_vendor.users.find_by_id(params[:id])
    login = @current_vendor.user_logins.find_by_id(params[:login])
    if login.user_id == @user.id and @current_user.role_cache.include? 'manager' then
      login.hide(@current_user)
    else
      raise "Ids Don't Match" + login.user.id.to_s + " ---- " + @current_user.role_cache
    end
    redirect_to "/users/#{@user.id}"
  end

  
  def index
    @users = @current_vendor.users.visible.order("created_at DESC").page(params[:page]).per(@current_vendor.pagination)
  end

  def show
    f, t = assign_from_to(params)
    @from = f
    @to = t
    @user = @current_vendor.users.visible.find_by_id(params[:id])
  end

  def new
    @user = User.new
    @user.language = 'en-US'
  end

  def edit
    @user = @current_vendor.users.visible.find_by_id(params[:id])
  end

  def create
    @user = User.new(params[:user])
    @user.vendor = @current_vendor
    @user.company = @current_company
    if @user.save
      redirect_to users_path
    else
      render :new
    end
  end

  def update
    @user = @current_vendor.users.visible.find_by_id(params[:id])
    if @user.update_attributes(params[:user])
      redirect_to users_path
    else
      render :edit
    end
  end

  def destroy
    @user = @current_vendor.users.visible.find_by_id(params[:id])
    @user.hide(@current_user)
    redirect_to users_path
  end
end
