# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorBase
  
  # this converts a date time:min:sec into a utc time, because
  # that is how we store them
  def self.convert_times_to_utc(t) 
    if t then
      format = "%Y-%m-%d %H:%M:%S"
      if t.is_a? Array then
        return t if t.empty?
        
        t.map! { |e| 
          if e.is_a? Array then
            #if it's an array of arrays, like a return from scan, recursively call it
            e = self.convert_times_to_utc(e) 
          else
            e = Time.strptime(e,format).utc.strftime(format) 
          end
        }
      else
        t = Time.strptime(t,format).utc.strftime(format)
      end 
      return t
    else
      return nil
    end
  end
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
  
  def hide(by)
    self.hidden = true
    self.hidden_at = Time.now
    self.hidden_by = by
    self.save
  end
  
  def log_action(txt="",color=:green)
    from = self.class.to_s
    SalorBase.log_action(from, txt, color)
  end
  
  def self.log_action(from="",txt="",color=:green)
  colors = {
    :black          => "\e[0;30;49m",
    :red            => "\e[0;31;49m",
    :green          => "\e[0;32;49m",
    :yellow         => "\e[0;33;49m",
    :blue           => "\e[0;34;49m",
    :magenta        => "\e[0;35;49m",
    :cyan           => "\e[0;36;49m",
    :white          => "\e[0;37;49m",
    :default        => "\e[0;39;49m",
    :light_black    => "\e[0;40;49m",
    :light_red      => "\e[0;91;49m",
    :light_green    => "\e[0;92;49m",
    :light_yellow   => "\e[0;93;49m",
    :light_blue     => "\e[0;94;49m",
    :light_magenta  => "\e[0;95;49m",
    :light_cyan     => "\e[0;96;49m",
    :light_white    => "\e[0;97;49m",
    :grey_on_red    => "\e[0;39;44m",
  }
    fromcolor = colors[:light_yellow]
    normalcolor = colors[:default]
    txtcolor = colors[color]
    if Rails.env == "development" then
      File.open("#{Rails.root}/log/development-history.log",'a') do |f|
        f.puts "##[#{fromcolor}#{from}] #{txtcolor}#{txt}#{normalcolor}\n"
      end
    end
    output = "#####[#{ fromcolor}#{from}] #{txtcolor}#{txt}#{ normalcolor }"
    ActiveRecord::Base.logger.info output
    puts output
  end
   
  def self.get_url(url, headers={}, user=nil, pass=nil)
    uri = URI.parse(url)
    headers ||= {}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    if user and pass then
      log_action "get_url: setting basic authentication"
      request.basic_auth(user,pass)
    end
    headers.each do |k,v|
      request[k] = v
    end
    log_action "get_url: starting request"
    response = http.request(request)
    log_action "get_url: finished request."
    return response
  end

  def self.post_url(url, headers, data, user=nil, pass=nil)
    uri = URI.parse(url)
    headers ||= {}
    raise "NoDataPassed" if data.nil?
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    if user and pass then
      request.basic_auth(user,pass)
    end
    if data.class == Hash then
      request.set_form_data(data)
    elsif data.class == String then
      request.body = data
    end
    headers.each do |k,v|
      request[k] = v
    end
    response = http.request(request)
    return response
  end
  
   
  def get_html_id
    return [self.class.to_s,self.id.to_s,rand(9999)].join('_').to_s
  end
  
  # deprecated in favor of Money
#   def self.number_to_currency(number,options={})
#     options.symbolize_keys!
#     defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
#     currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})
#     defaults[:negative_format] = "-" + options[:format] if options[:format]
#     options   = defaults.merge!(options)
#     unit      = I18n.t("number.currency.format.unit")
#     format    = I18n.t("number.currency.format.format")
#     value = self.number_with_precision(number)
#     format.gsub(/%n/, value).gsub(/%u/, unit)
#   end

  def self.string_to_float(str, options = { :locale => 'en-us' })
    return str if str.class == Float or str.class == Fixnum
    str = "0" if str.nil?
    str.gsub!(/[^-\d.,]/, '') # cleanup
    str.gsub! I18n.t('number.currency.format.delimiter', :locale => options[:locale]), ''
    str.gsub! I18n.t('number.currency.format.separator', :locale => options[:locale]), '.'
    return str.to_f
  end

  def string_to_float(string, options = { :locale => 'en-us' })
    return SalorBase.string_to_float(string, options)
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
    precision = options[:precision]
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

    defaults = I18n.translate('number.format', :locale => options[:locale], :default => {})
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
  def get_salor_errors()
    log_action "get_salor_errors was called in this request, but it deprecated."
    return []
  end
end
