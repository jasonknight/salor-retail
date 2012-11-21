# coding: UTF-8

# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Printr

  # mode can be local or sass
  # vendor_printers can either be a single VendorPrinter object, or an Array of VendorPrinter objects, or an ActiveRecord Relation containing VendorPrinter objects.
  def initialize(mode, vendor_printers=nil)
    @mode = mode
    @open_printers = Hash.new
    if vendor_printers.kind_of?(ActiveRecord::Relation) or vendor_printers.kind_of?(Array)
      @vendor_printers = vendor_printers
    elsif vendor_printers.kind_of? VendorPrinter
      @vendor_printers = [vendor_printers]
    else
      # If no available VendorPrinters are initialized, create a set of temporary VendorPrinters with usual device paths.
      puts "No VendorPrinters specified. Creating a set of temporary printers with usual device paths"
      paths = ['/dev/ttyUSB0', '/dev/ttyUSB1', '/dev/ttyUSB2', '/dev/usb/lp0', '/dev/usb/lp1', '/dev/usb/lp2', '/dev/salor-retail-front', '/dev/salor-retail-top', '/dev/salor-retail-back-top-left', '/dev/salor-retail-back-top-right', '/dev/salor-retail-back-bottom-left', '/dev/salor-retail-back-bottom-right']
      @vendor_printers = Array.new
      paths.size.times do |i|
        @vendor_printers << VendorPrinter.new(:name => paths[i].gsub(/^.*\//,''), :path => paths[i], :copies => 1)
      end
    end
  end

  def self.sanitize(text)
    text.force_encoding 'ISO-8859-15'
    char = ['ä', 'ü', 'ö', 'Ä', 'Ü', 'Ö', 'é', 'è', 'ú', 'ù', 'á', 'à', 'í', 'ì', 'ó', 'ò', 'â', 'ê', 'î', 'ô', 'û', 'ñ', 'ß']
    replacement = ["\x84", "\x81", "\x94", "\x8E", "\x9A", "\x99", "\x82", "\x8A", "\xA3", "\x97", "\xA0", "\x85", "\xA1", "\x8D", "\xA2", "\x95", "\x83", "\x88", "\x8C", "\x93", "\x96", "\xA4", "\xE1"]
    i = 0
    begin
      rx = Regexp.new(char[i].force_encoding('ISO-8859-15'))
      rep = replacement[i].force_encoding('ISO-8859-15')
      text.gsub!(rx, rep)
      i += 1
    end while i < char.length
    return text
  end

  def print(printer_id, text)
    return if @open_printers == {}
    ActiveRecord::Base.logger.info "[PRINTING]============"
    ActiveRecord::Base.logger.info "[PRINTING]PRINTING..."
    printer = @open_printers[printer_id]
    raise 'Mismatch between open_printers and printer_id' if printer.nil?
    ActiveRecord::Base.logger.info "[PRINTING]  Printing on #{ printer[:name] } @ #{ printer[:device].inspect.force_encoding('UTF-8') }."
    text.force_encoding 'ISO-8859-15'
    bytes_written = nil
    printer[:copies].times do |i|
      # The method .write works both for SerialPort object and File object, so we don't have to distinguish here.
      bytes_written = @open_printers[printer_id][:device].write text
      ActiveRecord::Base.logger.info "[PRINTING]ERROR: Byte count mismatch: sent #{text.length} written #{bytes_written}" unless text.length == bytes_written
    end
    # The method .flush works both for SerialPort object and File object, so we don't have to distinguish here.
    @open_printers[printer_id][:device].flush
    return bytes_written
  end

  def identify
    ActiveRecord::Base.logger.info "[PRINTING]============"
    ActiveRecord::Base.logger.info "[PRINTING]TESTING Printers..."
    open
    @open_printers.each do |id, value|
      text =
      "\e@"     +  # Initialize Printer
      "\e!\x38" +  # doube tall, double wide, bold
      "#{ I18n.t :printing_test }\r\n" +
      "\e!\x00" +  # Font A
      "#{ value[:name] }\r\n" +
      "#{ value[:device].inspect.force_encoding('UTF-8') }" +
      "\n\n\n\n\n\n" +
      "\x1D\x56\x00" # paper cut
      ActiveRecord::Base.logger.info "[PRINTING]  Testing #{ value[:device].inspect }"
      print id, Printr.sanitize(text)
      #print id, char_test
    end
    close
  end

  def char_test
    out = "\e@" # Initialize Printer
    0.upto(255) { |i| out += i.to_s(16) + i.chr }
    out += "\n\n\n\n\n\n" +
    "\x1D\x56\x00" # paper cut
    return out
  end

  def open
    ActiveRecord::Base.logger.info "[PRINTING]============"
    ActiveRecord::Base.logger.info "[PRINTING]OPEN Printers..."
    @vendor_printers.size.times do |i|
      p = @vendor_printers[i]
      name = p.name
      path = p.path
      if @mode != 'local' and SalorRetail::Application::SR_DEBIAN_SITEID != 'none'
        path = File.join('/', 'var', 'lib', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID, 'public', 'uploads', "#{path}.salor")
      end
      ActiveRecord::Base.logger.info "[PRINTING]  Trying to open #{ name } @ #{ path } ..."
      pid = p.id ? p.id : i
      begin
        printer = SerialPort.new path, 9600
        @open_printers.merge! pid => { :name => name, :path => path, :copies => p.copies, :device => printer }
        ActiveRecord::Base.logger.info "[PRINTING]    Success for SerialPort: #{ printer.inspect }"
        next
      rescue Exception => e
        ActiveRecord::Base.logger.info "[PRINTING]    Failed to open as SerialPort: #{ e.inspect }"
      end

      begin
        printer = File.open path, 'a:ISO-8859-15'
        @open_printers.merge! pid => { :name => name, :path => path, :copies => p.copies, :device => printer }
        ActiveRecord::Base.logger.info "[PRINTING]    Success for File: #{ printer.inspect }"
        next
      rescue Errno::EBUSY
        ActiveRecord::Base.logger.info "[PRINTING]    The File #{ path } is already open."
        ActiveRecord::Base.logger.info "[PRINTING]      Trying to reuse already opened printers."
        previously_opened_printers = @open_printers.clone
        previously_opened_printers.each do |key, val|
          ActiveRecord::Base.logger.info "[PRINTING]      Trying to reuse already opened File #{ key }: #{ val.inspect }"
          if val[:path] == p[:path] and val[:device].class == File
            ActiveRecord::Base.logger.info "[PRINTING]      Reused."
            @open_printers.merge! pid => { :name => name, :path => path, :copies => p.copies, :device => val[:device] }
            break
          end
        end
        unless @open_printers.has_key? p.id
          if SalorRetail::Application::SR_DEBIAN_SITEID == 'none'
            path = File.join(Rails.root, 'tmp')
          else
            path = File.join('/', 'var', 'lib', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID)
          end
          printer = File.open(File.join(path, "#{ p.id }-#{ name }-fallback-busy.salor"), 'a:ISO-8859-15')
          @open_printers.merge! pid => { :name => name, :path => path, :copies => p.copies, :device => printer }
          ActiveRecord::Base.logger.info "[PRINTING]      Failed to open as either SerialPort or USB File and resource IS busy. This should not have happened. Created #{ printer.inspect } instead."
        end
        next
      rescue Exception => e
        if SalorRetail::Application::SR_DEBIAN_SITEID == 'none'
          path = File.join(Rails.root, 'tmp')
        else
          path = File.join('/', 'var', 'lib', 'salor-retail', SalorRetail::Application::SR_DEBIAN_SITEID)
        end
        printer = File.open(File.join(path, "#{ p.id }-#{ name }-fallback-notbusy.salor"), 'a:ISO-8859-15')
        @open_printers.merge! pid => { :name => name, :path => path, :copies => p.copies, :device => printer }
        ActiveRecord::Base.logger.info "[PRINTING]    Failed to open as either SerialPort or USB File and resource is NOT busy. Created #{ printer.inspect } instead."
      end
    end
  end

  def close
    ActiveRecord::Base.logger.info "[PRINTING]============"
    ActiveRecord::Base.logger.info "[PRINTING]CLOSING Printers..."
    @open_printers.each do |key, value|
      begin
        value[:device].close
        ActiveRecord::Base.logger.info "[PRINTING]  Closing  #{ value[:name] } @ #{ value[:device].inspect }"
        @open_printers.delete(key)
      rescue Exception => e
        ActiveRecord::Base.logger.info "[PRINTING]  Error during closing of #{ value[:device].inspect.force_encoding('UTF-8') }: #{ e.inspect }"
      end
    end
  end
  
end