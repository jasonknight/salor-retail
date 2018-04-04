# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

require 'RMagick'
class Barcode
  
  def initialize(object)
    @path_prefix = File.join('public', 'uploads', SalorRetail::Application::SR_DEBIAN_SITEID)
    @sku = object.sku
    @vendor = object.vendor
    @path = ""
  end
  
  def create(type='39')
    @path = self.plot_path
    FileUtils.mkdir_p File.dirname(@path)
    epspath = "#{ @path }.eps"
    pngpath = "#{ @path }.png"
    begin
      system("barcode -c -b #{ @sku } -o #{ epspath } -e #{ type } -E")
      bc = Magick::ImageList.new(epspath)
      bc.write(pngpath)
    rescue
    end
    return @path.gsub("public", "")
  end

  def plot_path
    hash_id = @vendor.hash_id if @vendor
    hash_id = "unknown" if hash_id.blank?
    path = File.join(@path_prefix, hash_id, "images", "barcodes", @sku)
  end
  
#   def page(&block)
#     @_page ||= BarcodePage.new
#     yield @_page
#   end
#   
#   def get_page
#     return @_page
#   end
  
#   def page_test
#     page do |p|
#       p.barcodes = [123,456,789,10112,13,14,156,167,189,686,808098,900]
#       p.table = {:cols => 2, :rows => 8,:top => 1,:left => 1.5, :right => 1.5, :bottom => 2}
#       p.page_width = 210
#       p.page_height = 297
#       p.filename = "page_test.ps"
#       p.encoding = "39"
#       p.create
#     end
#   end
  
#   def user_key_codes(fname,name)
#     codes = []
#     puts "Starting: " + fname
#     File.open(fname,'r').each_line do |line|
#       parts = line.split("\t")
#       puts "Line: " + line
#       create(parts[0].gsub("U",""),'upc')
#     end
#     return
#     i = 0
#     while not codes.empty? do
#     page do |p|
#       p.barcodes = codes.slice!(0,12)
#       p.table = {:cols => 2, :rows => 8,:top => 1,:left => 1.5, :right => 1.5, :bottom => 2}
#       p.page_width = 210
#       p.page_height = 297
#       p.filename = "#{name}-#{i}.ps"
#       p.encoding = "39"
#       p.create
#     end
#     i = i + 1
#     end
#   end
end
