# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class ApiController < ApplicationController
#   skip_before_filter :verify_authenticity_token
#   before_filter :verify_input
#   # This should allow you to create an arbitrary object.
#   def create
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     cls = Kernel.const_get(@cmd[:data][:class_name])
#     if cls == Order then
#       model = @current_user.get_new_order
#       model.attributes = @cmd[:data][:attributes]
#       model.save
#       model.reload
#       model.calculate_totals
#     else
#       model = cls.new(@cmd[:data][:attributes])
#     end
#     respond_to do |format|
#       if not nil and @user and model.save then
#         if model.class == Order then
# 
#         end
#         format.json { render :text => success(model) }
#       else
#         format.json { render :text => failure(model) }
#       end
#     end
#   end
#   def update
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#       cls = Kernel.const_get(@cmd[:data][:class_name])
#       model = cls.scopied.find_by_id(@cmd[:data][:id])
#       if not model
#       end
#       respond_to do |format|
#         if @user and model and model.update_attributes(@cmd[:data][:attributes]) then
#           format.json { render :text => success(model) }
#         else
#           format.json { render :text => failure(model) }
#         end
#       end
#   end
#   def destroy
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#       cls = Kernel.const_get(@cmd[:data][:class_name])
#       model = cls.scopied.find_by_id(@cmd[:data][:id])
#       model.kill if model
#     respond_to do |format|
#       if @user and model then
#         format.json { render :text => success(model) }
#       else
#         format.json { render :text => failure(model.errors) }
#       end
#     end
#   end
#   def authenticate
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     respond_to do |format|
#       if @user then
#         format.json { render :text => success(I18n.t("api.you_are_authenticated")) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def time
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     respond_to do |format|
#       if @user then
#         format.json { render :text => success(Time.now.strftime("%Y-%m-%d %H:%I:%S")) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def search
#    @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       params[:per_page] ||= 25
#       cls = Kernel.const_get(@cmd[:data][:class_name])
#       models = cls.scopied.where("#{@cmd[:data][:field]} LIKE '%#{@cmd[:data][:value]}%'").page(params[:page]).per(params[:per_page])
#       total = cls.scopied.where("#{@cmd[:data][:field]} LIKE '%#{@cmd[:data][:value]}%'").count
#       res = {:results => models, :total => total}
#     end
#     respond_to do |format|
#       if models then
#         format.json { render :text => success(res) }
#       else
#         format.json { render :text => failure(I18n.t("api.nothing_found")) }
#       end
#     end
#   end
#   def order
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @order = Order.scopied.find_by_id(@cmd[:order_id])
#     end
#     respond_to do |format|
#       if @order then
#         format.json { render :text => success(@order) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def order_items
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @order = Order.scopied.find_by_id(@cmd[:order_id]).order_items
#     end
#     respond_to do |format|
#       if @order then
#         format.json { render :text => success(@order) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def registers
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @registers = CashRegister.scopied
#     end
#     respond_to do |format|
#       if @registers then
#         format.json { render :text => success(@registers) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def vendors
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @vendors = @current_user.vendors(params[:page])
#     end
#     respond_to do |format|
#       if @vendors then
#         format.json { render :text => success(@vendors) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def locations
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @locations = @current_user.get_locations(params[:page])
#     end
#     respond_to do |format|
#       if @locations then
#         format.json { render :text => success(@locations) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def categories
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @categories = @current_user.get_categories(params[:page])
#     end
#     respond_to do |format|
#       if @categories then
#         format.json { render :text => success(@categories) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def items
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @items = @current_user.get_items
#     end
#     respond_to do |format|
#       if @items then
#         format.json { render :text => success(@items) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def customers
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @customers = @current_user.get_customers(params[:page])
#     end
#     respond_to do |format|
#       if @customers then
#         format.json { render :text => success(@customers) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   def discounts
#     @user = auth
#     if not @user or nil
#       render :text => failure(I18n.t("api.wrong_params")) and return
#     end
#     if @user then
#       @discounts = @current_user.get_discounts(params[:page])
#     end
#     respond_to do |format|
#       if @discounts then
#         format.json { render :text => success(@discounts) }
#       else
#         format.json { render :text => failure(I18n.t("api.object_does_not_exist")) }
#       end
#     end
#   end
#   private
#   # You should only be able to access these objects
#   def allowed_classes
#     [
#      :user,:current_register,:category,
#      :location,:order,:order_item,:discount,
#      :customer, :table,:settlement, :quantity,
#      :option, :order_items_printoption, :order_items_option,
#      :vendor, :config, :item
#     ]
#   end
#   def auth
#     has_right_params(@cmd) # This is where input validation is taking place
#     # User.apitoken can be gotten from editing the User and saving the edit. 
#     user = User.select('id,username,vendor_id,user_id').where(['apitoken = ?',@cmd[:token]]).includes(:roles).first
#     if not user then
#       return nil
#     end
#     @current_user = user
#     if @current_user.nil? then
#       @current_user.save
#     end
#     if @current_user.get_drawer.nil? then
#       @current_user.get_drawer = Drawer.new
#       @current_user.get_drawer.save
#     end
#     vars = {}
#     var_names = [:sku,:controller,:action,:page,:vendor_id,:keywords]
#     var_names.each do |var|
#       vars[var.to_s] = params[var] 
#     end
#     
#     GlobalData.params = vars
#     
#     if @cmd[:vendor_id] then
#       @current_user.vendor_id = @cmd[:vendor_id]
#     end
#     if @cmd[:current_register_id] then
#       @current_register = @cmd[:current_register_id]
#     end
#     return user
#   end
#   def success(data,cnt=0)
#     {
#       :success => true,
#       :data => data,
#       :count => cnt,
#       :user => @current_user
#     }.to_json
#   end
#   def failure(data)
#     errors = []
#     GlobalErrors.all.each do |error|
#       errors << error[1]
#     end
#     errors << data
#     {
#       :success => false,
#       :data => errors,
#     }.to_json
#   end
#   def verify_input
#     if not params[:format] then
#       params[:format] = 'json'
#     end
#     if params[:format] == 'json' then
#       @cmd = JSON.parse(request.body.read)
#       @cmd = symbolize_keys @cmd
#     end
#   end
#   def required 
#     {
#       :except => [:authenticate,:vendors],
#       :every => {:vendor_id => Fixnum},
#       :create => {:data => Hash}
#     }
#   end
#   def has_right_params(cmd)
#     action = params[:action].to_sym
#     if required[:except].include? action then
#       return true
#     end
#     required[:every].each do |k,v|
#       if not cmd[k] then
#       end
#       if cmd[k] and not cmd[k].class == v then
#       end
#     end
#     if [:create,:update,:destroy,:search].include? action then
#       if cmd[:data][:class_name] and not allowed_classes.include? cmd[:data][:class_name].downcase.to_sym then
#       elsif not cmd[:data][:class_name]
#       end
#     end
#     # puts  GlobalErrors.all.inspect
#   end
#   def symbolize_keys arg
#     case arg
#     when Array
#       arg.map { |elem| symbolize_keys elem }
#     when Hash
#       Hash[
#         arg.map { |key, value|  
#           k = key.is_a?(String) ? key.to_sym : key
#           v = symbolize_keys value
#           [k,v]
#         }]
#     else
#       arg
#     end
#   end
end
