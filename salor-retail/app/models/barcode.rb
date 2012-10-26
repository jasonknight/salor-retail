# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

require 'RMagick'
class Barcode
  def create(code,type='39')
    return get_barcode(code) if File.exists?(eps_path(code)) and File.exists?(png_path(code))
    return make_barcode(code,type)
  end
  def make_barcode(string,type)
    begin
      system("barcode -c -b #{string} -o #{eps_path(string)} -e #{type} -E")
      bc = Magick::ImageList.new(eps_path(string))
      bc.write(png_path(string))
      return get_barcode(string)
    rescue
      return ''
    end
  end
  def get_barcode(string)
    "barcodes/#{string}.png"
  end
  def eps_path(string)
    if SalorRetail::Application::SR_DEBIAN_SITEID == 'none'
      return File.join(Rails.root, 'public', 'barcodes', "#{string}.eps")
    else
      File.join(Rails.root, 'public','barcodes',SalorRetail::Application::SR_DEBIAN_SITEID, "#{string}.eps")
    end
  end
  def png_path(string)
    if SalorRetail::Application::SR_DEBIAN_SITEID == 'none'
      return File.join(Rails.root, 'public', 'barcodes', "#{string}.png")
    else
      File.join(Rails.root, 'public','barcodes',SalorRetail::Application::SR_DEBIAN_SITEID, "#{string}.eps")
    end
  end
  def page(&block)
    @_page ||= BarcodePage.new
    yield @_page
  end
  def get_page
    return @_page
  end
  def page_test
    page do |p|
      p.barcodes = [123,456,789,10112,13,14,156,167,189,686,808098,900]
      p.table = {:cols => 2, :rows => 8,:top => 1,:left => 1.5, :right => 1.5, :bottom => 2}
      p.page_width = 210
      p.page_height = 297
      p.filename = "page_test.ps"
      p.encoding = "39"
      p.create
    end
  end
  def user_key_codes(fname,name)
    codes = []
    puts "Starting: " + fname
    File.open(fname,'r').each_line do |line|
      parts = line.split("\t")
      puts "Line: " + line
      create(parts[0].gsub("U",""),'upc')
    end
    return
    i = 0
    while not codes.empty? do
    page do |p|
      p.barcodes = codes.slice!(0,12)
      p.table = {:cols => 2, :rows => 8,:top => 1,:left => 1.5, :right => 1.5, :bottom => 2}
      p.page_width = 210
      p.page_height = 297
      p.filename = "#{name}-#{i}.ps"
      p.encoding = "39"
      p.create
    end
    i = i + 1
    end
  end
end
