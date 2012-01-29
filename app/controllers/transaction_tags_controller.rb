# coding: UTF-8
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
class TransactionTagsController < ApplicationController
  before_filter :authify
  before_filter :initialize_instance_variables
  before_filter :check_role, :except => [:crumble]
  before_filter :crumble
  # GET /transaction_tags
  # GET /transaction_tags.xml
  def index
    @transaction_tags = TransactionTag.scopied.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @transaction_tags }
    end
  end

  # GET /transaction_tags/1
  # GET /transaction_tags/1.xml
  def show
    @transaction_tag = TransactionTag.scopied.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @transaction_tag }
    end
  end

  # GET /transaction_tags/new
  # GET /transaction_tags/new.xml
  def new
    @transaction_tag = TransactionTag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @transaction_tag }
    end
  end

  # GET /transaction_tags/1/edit
  def edit
    @transaction_tag = TransactionTag.scopied.find(params[:id])
  end

  # POST /transaction_tags
  # POST /transaction_tags.xml
  def create
    @transaction_tag = TransactionTag.new(params[:transaction_tag])

    respond_to do |format|
      if @transaction_tag.save
        atomize(ISDIR, 'cash_drop')
        format.html { redirect_to(:action => "new", :notice => 'Transaction tag was successfully created.') }
        format.xml  { render :xml => @transaction_tag, :status => :created, :location => @transaction_tag }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @transaction_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /transaction_tags/1
  # PUT /transaction_tags/1.xml
  def update
    @transaction_tag = TransactionTag.scopied.find(params[:id])

    respond_to do |format|
      if @transaction_tag.update_attributes(params[:transaction_tag])
        atomize(ISDIR, 'cash_drop')
        format.html { redirect_to(:action => 'index', :notice => 'Transaction tag was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @transaction_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /transaction_tags/1
  # DELETE /transaction_tags/1.xml
  def destroy
    @transaction_tag = TransactionTag.scopied.find(params[:id])
    @transaction_tag.destroy
    atomize(ISDIR, 'cash_drop')
    respond_to do |format|
      format.html { redirect_to(transaction_tags_url) }
      format.xml  { head :ok }
    end
  end

  def logo
    @transaction_tag = TransactionTag.scopied.find(params[:id])
    send_data @transaction_tag.logo_image, :type => @transaction_tag.logo_image_content_type, :disposition => 'inline'
  end

  private 
  def crumble
    @vendor = GlobalData.salor_user.get_vendor(GlobalData.salor_user.meta.vendor_id)
    add_breadcrumb @vendor.name,'vendor_path(@vendor)'
    add_breadcrumb I18n.t("menu.transaction_tags"),'transaction_tags_path(:vendor_id => params[:vendor_id])'
  end
end
