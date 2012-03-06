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
module ApplicationHelper
  def salor_render(h)
    #t = "<!-- begin-partial #{h[:partial]}-->\n"
    t = raw(render(h))
    #t += "\n<!-- end-partial  #{h[:partial]}-->\n"
    return raw(t)
  end
  def add_param(p)
    @_params ||= {}
    @_params.merge!(p)
  end
  def get_params
    @_params ||= {}
    return @_params
  end
  def flatten_params
    s = []
    get_params.each do |k,v|
      s << "#{k}=#{v}"
    end
    return s.join("&")
  end
  def supported_languages
    [
      {:name => "Deutsch", :locale => 'de'},
      {:name => "US English", :locale => 'en-US'},
      {:name => "Français", :locale => 'fr'},
      {:name => "Espagnole", :locale => 'es'},
      {:name => "Türkçe", :locale => 'tr'}
    ]
  end
  def salor_number_to_currency(amnt)

    return number_to_currency(amnt)
  end
  def salor_number_with_delimiter(num)
    return number_with_delimiter(num)
  end
  def salor_signed_in?
    if session[:user_id] and session[:user_type] then
      return true
    else
      return false
    end
  end
  def salor_user
    if session[:user_id] then
      if session[:user_type] == "User" then
        return User.find session[:user_id]
      else
        return Employee.find session[:user_id]
      end
    end
  end
  def content_box_top(title, options = {:width => '90%', :small => false, :menu => true, :breadcrumb => true, :classes => []}, hideowner = false)
    classes = ['box-title','shadow']
    bbutton = '<div class="left-blank"></div>'
    rbtn = '<div class="right-blank"></div>'
    crumbs = ''
    options[:classes] ||= []
    adminclass = ''
    adminbox = ''
    if salor_signed_in? and salor_user.class == User and not hideowner then
      adminclass = '-admin'
      adminbox = '
        <div class="title-box-admin #{classes.join(" ")}">
          &#8226; ' + t("system.owner_mode") + ' &#8226;
          <div class="button-row-admin">
            <div class="button-admin" onclick="javascript:window.location.href=\'/home/edit_owner\';">' + t(:"menu.configuration") + '</div>
          </div>
        </div>'
    end
    if options[:small] then
      classes = ['small-title','shadow']
    else
      unless options[:menu] == false
        bbutton = '<div onclick="history.go(-1);" class="back-button' + adminclass + '"> &lt; </div>'
        rbtn = '<div onclick="window.location.reload();" class="reload-button' + adminclass + '"> &#x267A; </div>'
        crumbs = breadcrumbs
      end
    end

    %Q[
    <!-- content_box_top -->
    <div class="content-box content-box-#{params[:controller]}-#{params[:action]} #{options[:classes].join(' ')}">

      <div class="title-container">
          #{bbutton} <div class="title-box #{classes.join(' ')}">#{title}</div>  #{adminbox} #{rbtn}
          <div class="breadcrumb-container">
            #{crumbs}
          </div>
      </div>
      <div class="content-container content-container-#{params[:controller]}-#{params[:action]}">
    <!-- end content_box_top -->
    ]
  end
  def scrollable_table_top(headers = false)
    c = []
    h = ''
    if headers then
      headers.each do |th|
        if th.class == Hash then
          txt = th[:text]
          attrs = []
          th.each do |attr,value|
            attrs << "#{attr}=\"#{value}\"" if not attr == :text
          end
          c << "<th #{attrs.join(' ')}>#{txt}</th>"
        else
          c << "<th>#{th}</th>"
        end
      end
      h = '<thead class="fixedHeader"><tr>' + c.join("\n")+ '</tr></thead>'
    end
    %Q[
    <!-- scrollable_table_top -->
      <div id="table_container" class='tableContainer'>
        <table id="order_items_table" width="100%" class="ui-corner-all ui-widget ui-content stripe-me scrollTable">
        #{h}
        <tbody id="scroll_content" class='scrollContent'>
        <!-- end scrollable_table_top -->
    ]
  end
  def scrollable_table_bottom
    return "</tbody></table></div>\n <!-- end scrollable_table_bottom --> "
  end
  def content_box_bottom
    %q[
          </div>
        </div>
        <!-- content_box_bottom -->
    ]
  end
  def icon(name, size = '64')
    size = 32 if size == 16

    icons = {
      :location => 'clipboard',
      :category => 'binder',
      :vendor => 'home',
      :edit => 'document_pencil',
      :delete => 'delete',
      :add => 'plus',
      :item => 'bag1',
      :item_type => 'bag1',
      :show => 'info',
      :back => 'left',
      :next => 'right',
      :tax_profile => 'statistics',
      :employee => 'user_info',
      :reload => 'reload',
      :logout => 'logout',
      :login => 'login',
      :settings => 'gear',
      :home => 'gear',
      :cash_register => 'cashbox',
      :customer => 'user',
      :shipment => 'box',
      :shipper => 'shippers',
      :shipment_type => 'box_types',
      :stock_locations => 'shipment',
      :locked => 'lock',
      :unlocked => 'unlock',
      :discount => "star1",
      :order => "money",
      :help => "help",
      :up => 'up',
      :down => 'down',
      :cash_drop => 'coin_stack_gold',
      :refund => "arrow_down",
      :refunded => "arrow_up",
      :activate => "tick",
      :split => "arrow_divide",
      :ok => "tick",
      :printer => "print",
      :weight => "weight",
      :broken => "broken",
      :reorder => "reorder",
      :address => "address",
      :book => 'book',
      :book_balance => 'book_balance',
      :book_detail => 'book_detail',
      :book_sun => 'book_sun',
      :cash_drawer => 'drawer',
      :counter => 'counter',
      :wand => 'wand',
      :action => 'action',
      :payment => 'wallet',
      :locations => 'locations',
      :camera => "camera",
      :button => 'button',
      :card => 'credit_card',
      :print => 'print'
    }
    return icons[name] + '_' + size.to_s + '.png'
  end
  def salor_icon(name, options = {}, size = '64', caption=nil,caption_class='')
    if caption then
      o = []
      options.each do |k,v|
        o << "#{k}=\"#{v}\""
      end
      return raw("<div class=\"salor-icon\"><img src=\"/images/icons/#{icon(name,size)}\" #{o.join(" ")}/><br /><span class='icon-caption #{caption_class}'>#{caption}</span></div>")
    else
      return raw("<div class=\"salor-icon\">#{ image_tag('/images/icons/' + icon(name,size),options) }")
    end
  end
  def get_day(i)
    days = [

    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
    ]
    logger.info("### Recv: #{i} returning #{days[i - 1]}")
    return days[i-1]
  end
  def breadcrumbs
    path = []
    if not @breadcrumbs.nil? then
      if @breadcrumbs.length == 1 then
        return
      end
      if params[:action].to_s == 'edit' or params[:action].to_s == 'create' then
        #@breadcrumbs << [I18n.t("menu.new_#{params[:controller].to_s.singularize}"),eval("new_#{params[:controller].to_s.singularize}_path")]
      end
      @breadcrumbs.each do |l|
        path << link_to(l[0],l[1])
      end
      return path.join(' / ')
    end
  end
  def edit_me(field,model,initvalue='',withstring='',id=nil,update_pos_display='false')
    field = field.to_s
    if initvalue.blank? then
      initvalue = model.send(field)
    end
    initvalue = I18n.t("system.errors.value_not_set") if initvalue.blank? or initvalue.nil?
    if id.nil? then
      id = "inplaceedit_#{model.class.to_s}_#{field}_#{model.id}"
    end
    c = "editme #{model.class.to_s.downcase}-#{field}"
    return raw("<span model_id='#{model.id}' id='#{id}' class='#{c}' field='#{field}' klass='#{model.class.to_s}' data_type='#{model.send(field).class}' withstring='#{withstring}' update_pos_display='#{update_pos_display}'>#{initvalue}</span>")
  end

  def action_button(url,html,options={})
    opts = []
    options.each do |k,v|
      opts << "#{k}='#{v}'"
    end
    return raw "<span class=\"action-button\" url='#{url}' #{opts.join(' ')}>#{html}</span>"
  end
  def searchable_models
    [
      [I18n.t("activerecord.models.item.one"),'Item'],
      [I18n.t("activerecord.models.customer.one"),'Customer'],
      [I18n.t("activerecord.models.order.one"),'Order']
    ]
  end
  def get_help(key=nil,size=16,prms=nil)
    if prms.nil? then
      prms = params
    end
    k = prms[:controller]
    if not key.nil? then
      k = k + '_' + key
    end
    return salor_icon(:help, {:url => "/vendors/help?key=#{k}", :class => 'click-help', :style => "cursor:pointer;"},size)
  end
  def curl(url)
    c = "#{GlobalData.params[:controller]}##{GlobalData.params[:action]}"
    if c == url then
      return true
    else
      return false
    end
  end

  def generate_default_calendar_options
    options = []
    options.push('dateFormat : ' + t("date.formats.default").gsub("%Y", "yy").gsub("%y", "y").gsub("%m", "mm").gsub("%d", "dd").to_json)
    options.push('dayNames : ' + generate_calendar_names('day_names').to_json)
    options.push('dayNamesShort : ' + generate_calendar_names('abbr_day_names').to_json)
    options.push('dayNamesMin : ' + generate_calendar_names('abbr_day_names').to_json)
    month_names = generate_calendar_names('month_names')
    month_names.shift if month_names.length > 12 # Remove the '~' entry
    options.push('monthNames : ' + month_names.to_json)
    abbr_month_names = generate_calendar_names('abbr_month_names')
    abbr_month_names.shift if abbr_month_names.length > 12 # Remove the '~' entry
    options.push('monthNamesShort : ' + abbr_month_names.to_json)
    #options.push('currentText : ' + t(:today).to_json)
  end

  def generate_calendar_names(type)
    t("date.#{type}")
  end

  def generate_calendar_date_format
    format = t("date.formats.default")
  end

  def get_clock_content
    tm = l(Time.now, :format => :salor)
    tarr = tm.split(' ')
    ret = ''
    ret << "<span>#{tarr[3]}</span><br />#{tarr[0]} #{tarr[1]} #{tarr[2]}<br />#{$User.username}"

    return ret.html_safe
  end
  def num2name(num)
    num = num.to_s.gsub('0.','').gsub(',','').gsub('.','')
  end
  def leftpad(str,chars,pad=' ')
    return str if str.length >= chars
    len = str.length
    begin
      str = pad + str
      len = len + 1
    end until len >= chars
    return str
  end
  def true_false_select
    return [
    ["False",false],
    ["True",true]
    ]
  end
end
