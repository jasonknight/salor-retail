# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorBase
  VERSION = '{{VERSION}}'
  
  def self.symbolize_keys arg
    case arg
    when Array
      arg.map { |elem| symbolize_keys elem }
    when Hash
      Hash[
        arg.map { |key, value|  
          k = key.is_a?(String) ? key.to_sym : key
          v = symbolize_keys value
          [k,v]
        }]
    else
      arg
    end
  end
  
  def log_action(txt)
    SalorBase.log_action(self.class.to_s,txt)
  end
  
  def self.log_action(from="unk",txt)
    ActiveRecord::Base.logger.info "[#{from}] #{txt}"
  end
  
  def self.string_to_float(str)
    return str if str.class == Float or str.class == Fixnum
      string = "#{str}"
      #puts string
      string.gsub!(/[^-\d.,]/,'')
      #puts string
      if string =~ /^.*[\.,]\d{1}$/
        string = string + "0"
      end
     # puts string
      unless string =~ /^.*[\.,]\d{2,3}$/
        string = string + "00"
      end
      #puts string
      return string if string.class == Float or string.class == Fixnum or string == 0
      if string =~ /^.*[\.,]\d{3}$/ then
         string.gsub!(/[\.,]/,'')
         string = string.to_f / 1000
         #puts string
      else
        string.gsub!(/[\.,]/,'')
        string = string.to_f / 100
        #puts string
      end
      #puts string
      return string
   end
   
   def string_to_float(string)
      return SalorBase.string_to_float(string)
   end
   
   def get_gs1_price(code, item=nil)
     m = code.match(/\d{2}(\d{5})(\d{5})\d{0,1}/)
     if not m then
       return nil
     end
     if item and item.decimal_points.to_i == 3 then
       parts = m[2].match(/(\d{2})(\d{3})/)
       # puts parts.inspect
     else
       parts = m[2].match(/(\d{3})(\d{2})/)
     end
     num = "#{parts[1]}.#{parts[2]}".to_f
     return num
   end
   
   def get_html_id
     return [self.class.to_s,self.id.to_s,rand(9999)].join('_').to_s
   end
   
   def self.rebate_types
     return [
     [I18n.t("system.rebates.percent"),'Percent'],
     [I18n.t("system.rebates.fixed"),'Fixed']
     ]
   end
   
   def salor_fetch_attr(attr,options = {})
     begin
       conn = ActiveRecord::Base.connection();
       options[:table] ||= self.table_name
       options[:return_cast] ||= :to_f
       if options[:conditions] then
         if options[:conditions].class == String then
           conditions = options[:conditions]
         else
           pairs = []
           options[:conditions].each do |k,v|
            pairs << "`#{k}` = '#{v}'"
           end
           conditions = pairs.join(" AND ")
         end
       end
       sql = "select `#{options[:table]}`.`#{attr}` from `#{options[:table]}` where #{conditions}"
       value = conn.execute(sql)
       value = value.to_a.first if value.respond_to? :to_a
       return 0 if value.nil?
       value = value.first
       value = 0 if value.nil?
       return value.send(options[:return_cast])
     rescue
       return 0
     end
   end

   
   def set_model_owner(user=nil)
      if user.nil? then
       user = @current_user
      end
      return if user.nil?

      if self.respond_to? :owner_id and self.owner_id.nil? then
        self.owner_id = user.id
        self.owner_type = user.class.to_s
      end
      if self.respond_to? :vendor_id and self.vendor_id.nil? then
       self.vendor_id = user.vendor_id
       self.set_sku if self.class == Category or self.class == Customer
      end
      if self.respond_to? :current_register_id and self.current_register_id.nil? then
        self.current_register_id = user.get.current_register_id
      end
      if self.respond_to? :user_id and self.user_id.nil? then
       self.user_id = user.get_owner.id
      end
      if self.respond_to? :user_id and self.user_id.nil? then
         if user.is_user? then
           self.user_id = user.id
         end
      end
   end

  
  def self.to_currency(number,options={})
    options.symbolize_keys!
    defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})
    defaults[:negative_format] = "-" + options[:format] if options[:format]
    options   = defaults.merge!(options)
    unit      = I18n.t("number.currency.format.friendly_unit")
    format    = I18n.t("number.currency.format.format")
    if number.to_f < 0
      format = options.delete(:negative_format)
      number = number.respond_to?("abs") ? number.abs : number.sub(/^-/, '')
    end
    value = self.number_with_precision(number)
    format.gsub(/%n/, value).gsub(/%u/, unit)
  end
  
  def self.number_to_currency(number,options={})
    options.symbolize_keys!
    defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})
    defaults[:negative_format] = "-" + options[:format] if options[:format]
    options   = defaults.merge!(options)
    unit      = I18n.t("number.currency.format.unit")
    format    = I18n.t("number.currency.format.format")
    if number.to_f < 0
      format = options.delete(:negative_format)
      number = number.respond_to?("abs") ? number.abs : number.sub(/^-/, '')
    end
    value = self.number_with_precision(number)
    format.gsub(/%n/, value).gsub(/%u/, unit)
  end

  def self.number_with_precision(number, options = {})
    options.symbolize_keys!

    number = begin
      Float(number)
    rescue ArgumentError, TypeError
      if options[:raise]
        raise InvalidNumberError, number
      else
        return number
      end
    end

    defaults           = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    precision_defaults = I18n.translate(:'number.precision.format', :locale => options[:locale], :default => {})
    defaults           = defaults.merge(precision_defaults)

    options = options.reverse_merge(defaults)  # Allow the user to unset default values: Eg.: :significant => false
    precision = 2
    significant = options.delete :significant
    strip_insignificant_zeros = options.delete :strip_insignificant_zeros

    if significant and precision > 0
      if number == 0
        digits, rounded_number = 1, 0
      else
        digits = (Math.log10(number.abs) + 1).floor
        rounded_number = (BigDecimal.new(number.to_s) / BigDecimal.new((10 ** (digits - precision)).to_f.to_s)).round.to_f * 10 ** (digits - precision)
        digits = (Math.log10(rounded_number.abs) + 1).floor # After rounding, the number of digits may have changed
      end
      precision = precision - digits
      precision = precision > 0 ? precision : 0  #don't let it be negative
    else
      rounded_number = BigDecimal.new(number.to_s).round(precision).to_f
    end
    formatted_number = self.number_with_delimiter("%01.#{precision}f" % rounded_number, options)
    return formatted_number
  end
  
  def self.number_with_delimiter(number, options = {})
    options.symbolize_keys!

    begin
      Float(number)
    rescue ArgumentError, TypeError
      if options[:raise]
        raise InvalidNumberError, number
      else
        return number
      end
    end

    defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    options = options.reverse_merge(defaults)

    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
    return parts.join(options[:separator])
  end
  
  def csv_header(sep=";")
    values = []
    self.class.content_columns.each do |col|
      values << "#{self.class.table_name}.#{col.name.to_sym}"
    end
    values.join(sep)
  end
  
  def to_csv(sep=";")
    values = []
    self.class.content_columns.each do |col|
      values << self.send(col.name.to_sym)  
    end
    return values.join(sep)
  end
end
