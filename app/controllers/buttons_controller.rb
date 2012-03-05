# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
class ButtonsController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  
  def index
    @button_categories = Category.where(:button_category => true).order(:position)
  end
  #
  def show
    @button = Button.scopied.find(params[:id])
  end

  def new
    @button = Button.new(params[:item])
    @button_categories = Category.where(:button_category => true).order(:position)
  end

  def edit
    @button = Button.scopied.find_by_id(params[:id])
    @button_categories = Category.where(:button_category => true).order(:position)
  end

  def create
    @button = Button.new(params[:button])
    @button.set_model_owner
    respond_to do |format|
      if @button.save
        format.html { redirect_to(buttons_url, :notice => 'Button was successfully created.') }
        format.xml  { render :xml => @button, :status => :created, :location => @button }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @button.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @button = Button.scopied.find_by_id(params[:id])

    @button.update_attributes params[:button]
    redirect_to buttons_path
  end

  def destroy
    @button = Button.scopied.find_by_id(params[:id])
  @button.kill if @button

    respond_to do |format|
      format.html { redirect_to(buttons_url) }
      format.xml  { head :ok }
    end
  end
  #
  def position
    @buttons = Button.scopied.where("id IN (#{params[:button].join(',')})")
    Button.sort(@buttons,params[:button])
    render :nothing => true
  end

  private 

  def crumble
    @vendor = salor_user.get_vendor(salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.buttons"),'buttons_path(:vendor_id => params[:vendor_id])'
  end
end
