# coding: UTF-8

module Printr
  mattr_accessor :encoding
  @@encoding = 'ISO-8859-15'
  mattr_accessor :debug
  @@debug = false
  mattr_accessor :serial_baud_rate
  @@serial_baud_rate = 9600
  mattr_accessor :scope
  @@scope = 'printr' # essential what views directory to look in for the
                     # templates
  mattr_accessor :printr_source        #:yaml or :active_record
  @@printr_source = :yaml              # :active_record => {:class_name => ClassName, :name => :model_field_name, :path => :model_path_name
                                       # E.G. printr_model = {:class_name => Printer, :name => :short_name, :path => :location }
                                       # to create the list of printers it will call: 
                                       # Printer.all.each { |p| @printrs[p.send(Printr.printr_model[:name].snake_case.to_sym)] = p.send(Printr.printr_model[:path]) }
                                       # so if you have a printer named bar_printer, then you can print to it with @printr.bar_printer 'textl'
  mattr_accessor :logger               # Expects STDOUT[Default], A logger, or a File Descriptor via File.open
  @@logger = STDOUT
  
  mattr_accessor :sanitize_tokens      #pair list of needle regex, replace must be by 2s, i.e. [/[abc]/,"x",/[123]/,'0']
  @@sanitize_tokens = []
  mattr_accessor :codes
  @@codes = {
      :initialize => "\e@",
      :papercut => "\x1DV\x00"
    }
  mattr_accessor :printrs
  @@printrs = {}
  mattr_accessor :conf
  @@conf = {}
  def self.new
     return Printr::Machine.new
  end
  def self.log(text)
    return if not Printr.debug
    text = "[Printr] #{text}" if not text.include?('[Printr]')
    if @@logger == STDOUT
      @@logger.puts
    else
      if @@logger.respond_to? :info
        @@logger.info text
      elsif @@logger.respond_to? :puts
        @@logger.puts text
      else
        puts text
      end
    end
  end
  def self.setup
    yield self
  end
  def self.get_printers
    Printr.log "Getting Printers"
    if @@printr_source == :yaml then
      Printr.log "printr_source == :yaml"
      @@conf = YAML::load(File.open("#{::Rails.root.to_s}/config/printrs.yml")) 
    elsif @@printr_source.class == Hash then
      if @@printr_source[:active_record] then
          Printr.log "printr_source == :active_record"
          @@printr_source[:active_record][:class_name].all.each do |p|
            key = p.send(@@printr_source[:active_record][:name]).to_sym
            Printr.log "conf[#{key}] = #{p.send(@@printr_source[:active_record][:path])}"
            @@conf[key] = p.send(@@printr_source[:active_record][:path])
          end
      end
    end
    return self.open_printers
  end
  def self.open_printers
    @@conf.each do |key,value|
      @@printrs[key] = value
     end
     Printr.log "open_printers returning: " + @@printrs.inspect
    @@printrs
  end 


  # Instance Methods
  class Machine
    def initialize()
      Printr.get_printers
      # You can access these within the views by calling @printr.codes, or whatever
      # you named the instance variable, as it will be snagged by the Binding
      @codes = Printr.codes
      
      # You can override the above codes in the printers.yml, to add
      # say an ASCII header or some nonsense, or if they are using a
      # standard printer etc etc.
      if Printr.conf[:codes] then
        Printr.conf[:codes].each do |key,value|
          Printr.conf[key.to_sym] = value
        end
      end
      Printr.open_printers
    end
    
    def test(key)
      
    end
    
    def print_to(key,text)
      Printr.log "[Printr] print_to(#{key},#{text[0..55]})"
      key = key.to_sym
      if text.nil? then
        Printr.log "[Printr] Umm...text is nil dudes..."
        return
      end
      text = sanitize(text)
      if text.nil? then
        Printr.log "[Printr] Sanitize nillified the text..."
      end
      Printr.log "[Printr] Going ahead with printing of: " + text.to_s[0..55]

      Printr.log "[Printr] Printing to device..." + Printr.conf[key]
      begin
        Printr.log "[Printr] Trying to open #{key} #{Printr.printrs[key]} as a SerialPort."
        SerialPort.open(Printr.printrs[key],9600) do |sp|
          sp.write text
        end
        return
      rescue Exception => e
        Printr.log "[Printr] Failed to open #{key} #{Printr.printrs[key]} as a SerialPort: #{e.inspect}. Trying as a File instead."
      end
      begin
        File.open(Printr.conf[key],'w:ISO8859-15') do |f|
          Printr.log "[Printr] Writing text."
          text.force_encoding 'ISO-8859-15'
          f.write text
        end
      rescue Exception => e
        Printr.log "[Printr] Failed to open #{key} #{Printr.printrs[key]} as a File."
      end
    end
#
    def direct_write(file_path,text)
      begin
        File.open(file_path,'w:ISO8859-15') do |f|
          Printr.log "[Printr] Writing text."
          text.force_encoding 'ISO-8859-15'
          f.write text
        end
      rescue Exception => e
        Printr.log "[Printr] Failed to open #{file_path} as a File. #{e.inspect}"
      end
    end
#
    def method_missing(sym, *args, &block)
      Printr.log "[Printr] Called with: #{sym}"
      if Printr.printrs[sym] then
        if args[1].class == Binding then
          Printr.log "Binding was passed"
          print_to(sym,template(args[0],args[1])) #i.e. you call @printr.kitchen('item',binding)
        else
          Printr.log "No Binding was passed"
          print_to(sym,args[0])
        end
      end
    end

    def sanitize(text)
      # Printr.sanitize_tokens is a pair array, that is index 0 is the needle and 1 is the replace, 2 is the needle
      # 3 the replacement etc. [needle,replace,needle,replace,needle,replace]
      Printr.log "sanitize(#{text[0..55]})"
      Printr.log "Forcing encoding to: " + Printr.encoding # Printr.encoding can be set in initializer with config.encoding = ISO-8859-15 etc
      text.encode! Printr.encoding
      char = ['ä', 'ü', 'ö', 'Ä', 'Ü', 'Ö', 'é', 'è', 'ú', 'ù', 'á', 'à', 'í', 'ì', 'ó', 'ò', 'â', 'ê', 'î', 'ô', 'û', 'ñ', 'ß']
      replacement = ["\x84", "\x81", "\x94", "\x8E", "\x9A", "\x99", "\x82", "\x8A", "\xA3", "\x97", "\xA0", "\x85", "\xA1", "\x8D", "\xA2", "\x95", "\x83", "\x88", "\x8C", "\x93", "\x96", "\xA4", "\xE1"]
      i = 0
      Printr.log "Adding some tokens to the sanitize array"
      begin
        rx = Regexp.new(char[i].encode(Printr.encoding))
        rep = replacement[i].force_encoding(Printr.encoding)
        Printr.sanitize_tokens << rx
        Printr.sanitize_tokens << rep
        i += 1
      end while i < char.length
      i = 0
      begin
        rx = Printr.sanitize_tokens[i]
        rep = Printr.sanitize_tokens[i+1]
        #Printr.log "Replacing: " + rx.to_s + " with " + rep.to_s
        begin
          text.gsub!(rx, rep)
        rescue
        end
        i += 2
      end while i < Printr.sanitize_tokens.length
      return text
    end

    def sane_template(name,bndng)
      Printr.log "[Printr] attempting to print with template #{::Rails.root.to_s}/app/views/#{Printr.scope}/#{name}.prnt.erb"
      begin
        erb = ERB.new(File.new("#{::Rails.root.to_s}/app/views/#{Printr.scope}/#{name}.prnt.erb",'r').read,0,'>')
      rescue Exception => e
        Printr.log "[Printr] Exception in view: " + $!.inspect
      end
      Printr.log "[Printr] returning text"
      text = erb.result(bndng)
      if text.nil? then
        text = 'erb result made me nil'
      end
      return sanitize(text)
    end
    def template(name,bndng)
      Printr.log "[Printr] attempting to print with template #{::Rails.root.to_s}/app/views/#{Printr.scope}/#{name}.prnt.erb"
      begin
        erb = ERB.new(File.new("#{::Rails.root.to_s}/app/views/#{Printr.scope}/#{name}.prnt.erb",'r').read,0,'>')
      rescue Exception => e
        Printr.log "[Printr] Exception in view: " + $!.inspect
      end
      Printr.log "[Printr] returning text"
      text = erb.result(bndng)
      if text.nil? then
        text = 'erb result made me nil'
      end
      return text
    end

  end
end




Printr.setup do |config|
  config.printr_source = {:active_record => {
    :class_name => VendorPrinter,
    :name => :name,
    :path => :path
  }}
  #config.sanitize_tokens = ['$','\$']
  config.debug = false
  #config.sanitize = true
  config.encoding = 'ISO-8859-15'
  #config.logger = File.open("/tmp/printr.txt",'a')
end
