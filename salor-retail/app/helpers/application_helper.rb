# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
module ApplicationHelper
 
  # TODO: salor_render should be depreciated in favor of plain Rails render, since it does nothing
  def salor_render(h)
    #t = "<!-- begin-partial #{h[:partial]}-->\n"
    t = raw(render(h))
    #t += "\n<!-- end-partial  #{h[:partial]}-->\n"
    return raw(t)
  end
  def link_to_add_fields(name, f, association,jsfunc)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "#{jsfunc}(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
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
      {:name => "Deutsch", :locale => 'gn'},
      {:name => "US English", :locale => 'en-US'},
      {:name => "GB English", :locale => 'en-GB'},
      {:name => "CA English", :locale => 'en-CA'},
      {:name => "ελληνική", :locale => 'el'},
      {:name => "Français", :locale => 'fr'},
      {:name => "Espagnole", :locale => 'es'},
      {:name => "中文", :locale => 'cn'}
    ]
  end
  
  def salor_number_to_currency(amnt)
    return number_to_currency(amnt, :unit => I18n.t("number.currency.format.unit"))
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
        return User.find_by_id(session[:user_id])
      else
        return Employee.find_by_id(session[:user_id])
      end
    end
  end
  
  def content_box_top(title, options = {:width => '90%', :small => false, :menu => true, :breadcrumb => true, :classes => []}, hideowner = false)
    clses = ['box-title','shadow']
    bbt = '<div class="left-blank"></div>'
    rbtn = '<div class="right-blank"></div>'
    crumbs = ''
    options[:classes] ||= []
    adminclass = ''
    adminbox = ''
    if salor_signed_in? and salor_user.class == User and not hideowner then
      adminclass = '-admin'
      adminbox = '
        <div class="title-box-admin #{clses.join(" ")}">
          &#8226; ' + t("system.owner_mode") + ' &#8226;
#           <div class="button-row-admin">
            <div class="button-admin" onclick="javascript:window.location.href=\'/home/edit_owner\';">' + t(:"menu.configuration") + '</div>
          </div>
        </div>'
    end
    if options[:small] then
      classes = ['small-title','shadow']
    else
      unless options[:menu] == false
        bbt = '<div onclick="history.go(-1);" class="back-button' + adminclass + '"> &lt; </div>'
        rbtn = '<div onclick="window.location.reload();" class="reload-button' + adminclass + '"> &#x267A; </div>'
        crumbs = breadcrumbs
      end
    end

    %Q[
    <div class="content-box content-box-#{params[:controller]}-#{params[:action]} #{options[:classes].join(' ')}">
      <div class="title-container">
          #{bbt} <div class="title-box #{clses.join(' ')}">#{title}</div>  #{adminbox} #{rbtn}
          <div class="breadcrumb-container">
            #{crumbs}
          </div>
      </div>
    ]
  end
  def content_box_bottom
    ''
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
      :info => 'info',
      :back => 'left',
      :next => 'right',
      :tax_profile => 'statistics',
      :statistics => 'statistics',
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
      :print => 'print',
      :a4print => 'a4print',
      :document => 'document',
      :trash => 'trash',
      :user6 => 'user6',
      :user7 => 'user7',
      :nurse => 'user2',
      :save => 'save',
      :gearpage => 'gearpage',
      :label => 'label',
      :bubble => 'bubble',
      :buy => 'buy',
      :globe => 'globe',
      :invoice_blurb => 'book'
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
      return raw("<div class=\"salor-icon\">#{ image_tag('/images/icons/' + icon(name,size),options) }</div>")
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
    reg = nil
    reg = CashRegister.find_by_id($User.meta.cash_register_id) if $User
    ret << "<span>#{tarr[3]}</span><br />#{tarr[0]} #{tarr[1]} #{tarr[2]}<br />#{$User.username if $User}<br />#{ reg.name if reg }"
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
  # {END}
end
