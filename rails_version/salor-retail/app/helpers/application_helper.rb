# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
module ApplicationHelper
 

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
  
  def salor_number_to_currency(amnt)
    return number_to_currency(amnt, :locale => @region)
  end
  
  def salor_number_with_delimiter(num)
    return number_with_delimiter(num, :locale => @region)
  end
  
  def content_box_top(title, options = {:width => '90%', :small => false, :menu => true, :classes => []})
    clses = ['box-title','shadow']
    bbt = '<div class="left-blank"></div>'
    rbtn = '<div class="right-blank"></div>'
    options[:classes] ||= []

    if options[:small] then
      classes = ['small-title','shadow']
    else
      unless options[:menu] == false
        bbt = "<div onclick=\"window.location='/#{ params[:controller] }';\" class='back-button'> &lt; </div>"
        rbtn = "<div onclick='window.location.reload();' class='reload-button'> &#x267A; </div>"
      end
    end

    %Q[
    <div class="content-box content-box-#{params[:controller]}-#{params[:action]} #{options[:classes].join(' ')}">
      <div class="title-container">
          #{bbt} <div class="title-box #{clses.join(' ')}">#{title}</div> #{rbtn}
      </div>
    </div>
    ]
  end
  

  def get_icons_map
    icons = {
      :gift_card => 'gift_card',
      :subscription_order => 'subscription_order',
      :add_item => 'add_item',
      :location => 'location',
      :search => 'search',
      :category => 'category',
      :vendor => 'home',
      :edit => 'edit',
      :delete => 'delete',
      :delete => 'delete',
      :add => 'add',
      :item => 'item',
      :merge => "merge",
      :history => "agenda",
      :item_type => 'bag1',
      :show => 'play',
      :info => 'puzzle',
      :back => 'left',
      :next => 'right',
      :tax_profile => 'percent',
      :statistics => 'chart',
      :user => 'user',
      :pin => 'pin',
      :reload => 'reload',
      :logout => 'key',
      :login => 'key',
      :settings => 'gear',
      :home => 'vendor',
      :current_register => 'till',
      :cash_register => 'till',
      :customer => 'customer',
      :shipment => 'shipment',
      :shipper => 'shipper',
      :shipment_type => 'status',
      :wrench => 'wrench',
      :stock_locations => 'stock_locations',
      :stock_location => 'stock_locations',
      :item_stock => 'item',
      :locked => 'lock',
      :unlocked => 'unlock',
      :discount => "discount",
      :order => "order",
      :unpaid_order => "unpaid_order",
      :proforma_order => "proforma_order",
      :quote => "quote_order",
      :help => "help",
      :up => 'up',
      :down => 'down',
      :cash_drop => 'coin',
      :refund => "return",
      :refunded => "return2",
      :activate => "tick",
      :split => "arrow_divide",
      :ok => "tick",
      :printer => "print",
      :thermal_printer => 'printer_thermal',
      :sticker_printer => 'printer_sticker',
      :weight => "scale",
      :weigh => "scale",
      :broken => "broken",
      :broken_item => "broken",
      :reorder => "redo",
      :address => "address",
      :book => 'book',
      :book_balance => 'book_balance',
      :book_detail => 'book_detail',
      :book_sun => 'book_sun',
      :cash_drawer => 'cash_drawer',
      :counter => 'counter',
      :inventory_report => 'counter',
      :wand => 'wand',
      :update_real_quantity => 'okay',
      :okay => 'okay',
      :okay_orange => 'okay-orange',
      :action => 'gears',
      :plugin => 'gears',
      :payment => 'payment_method',
      :payment_method => 'payment_method',
      :locations => 'location',
      :camera => "camera",
      :button => 'button',
      :card => 'credit_card',
      :print => 'print',
      :a4print => 'a4print',
      :document => 'agenda',
      :trash => 'trash',
      :user6 => 'user6',
      :user7 => 'user7',
      :nurse => 'help',
      :save => 'save',
      :gearpage => 'gears',
      :label => 'printer_sticker',
      :bubble => 'bubble',
      :buy => 'buy',
      :globe => 'globe',
      :country => "globe",
      :invoice_blurb => 'bubble',
      :invoice_note => 'edit_pad2',
      :tags => 'tag',
      :transaction_tag => 'tag',
      :sale_type => 'pad',
      :save_download => 'save_download',
      :save_upload => 'save_upload',
      :report => 'edit_pad'
    }
    return icons
  end
  
  def icon(name, size = '64')
    return :edit if name.nil?
    name = name.to_sym
    icons = get_icons_map
    return icons[name] + '.svg'
  end
  
  def salor_icon(name, options = {}, size = '64', caption=nil,caption_class='')
    #name = @current_plugin_manager.apply_filter('salor_icon',name) if @current_plugin_manager
    if caption then
      o = []
      options.each do |k,v|
        o << "#{k}=\"#{v}\""
      end
      return raw("<div class=\"salor-icon\"><img height=\"#{size}\" src=\"/images/icons/#{icon(name,size)}\" #{o.join(" ")}/><br /><span class='icon-caption #{caption_class}'>#{caption}</span></div>")
    else
      options[:height] ||= size
      return raw("<div class=\"salor-icon\">#{ image_tag('/images/icons/' + icon(name,size).to_s,options) }</div>")
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
  
  def searchable_models
    [
      [I18n.t("activerecord.models.item.one"),'Item'],
      [I18n.t("activerecord.models.customer.one"),'Customer'],
      [I18n.t("activerecord.models.order.one"),'Order']
    ]
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

  
  def nest_image(object)
    object.tap do |o|
      if o.images.empty? then
        o.images.build
        o.images.first.image_type = 'logo' if o.class.name == 'Vendor' and o.images.first.image_type.nil?
      end
      if o.class.name == 'Vendor' and o.images.count < 2 then
        o.images.first.image_type = 'logo' if o.images.first.image_type.nil?
        o.images.build
        o.images.first.image_type == 'logo' ? o.images.last.image_type = 'invoice_logo' : o.images.last.image_type = 'logo'
      end
    end
  end
end
