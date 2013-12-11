# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class UsersController < ApplicationController
  
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
    redirect_to '/saas/users/new' and return if defined?(SrSaas) == 'constant'
    @user = User.new
    @user.language = 'en'
  end

  def edit
    redirect_to "/saas/users/#{ params[:id] }/edit" and return if defined?(SrSaas) == 'constant'
    @user = @current_vendor.users.visible.find_by_id(params[:id])
  end

  def create
    @user = User.new(params[:user])
    @user.vendors << @current_vendor
    @user.company = @current_company
    if @user.save
      @user.set_drawer
      redirect_to users_path
    else
      render :new
    end
  end

  def update
    @user = @current_vendor.users.visible.find_by_id(params[:id])
    if @user.update_attributes(params[:user])
      if @current_user == @user
        session[:locale] = @user.language
      end
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
  
  def destroy_login
    @user = @current_company.users.find_by_id(params[:id])
    login = @current_company.user_logins.find_by_id(params[:login])
    if login.user_id == @user.id and @current_user.role_cache.include? 'manager' then
      login.hide(@current_user.id)
    else
      raise "No permission or Ids Don't Match " + login.user.id.to_s + " ---- " + @current_user.role_cache
    end
    redirect_to user_path(@user)
  end
  
  def clockin
    if params[:password] then
      u = @current_company.login(params[:password])
      if not u then
        render :text => "NO" and return
      else
        login = @current_company.user_logins.where(:user_id => u.id).last
        if login and login.logout.nil? then
          render :text => "ALREADY" and return
        end
        u.start_day(@current_vendor)
        render :json => {:username => u.username, :id => u.id} and return
      end
    end
  end
  
  def clockout
    if params[:password] then
      u = @current_company.login(params[:password])
      if not u then
        render :text => "NO" and return
      else
        u.end_day
        render :json => {:username => u.username, :id => u.id} and return
      end
    end
  end
  
  def verify
    if params[:password] then
      emp = @current_company.login(params[:password])
      if not emp then
        render :text => "NO" and return
      else
        render :json => {
          :username => emp.username,
          :id => emp.id
        } and return
      end
    end
  end
end
