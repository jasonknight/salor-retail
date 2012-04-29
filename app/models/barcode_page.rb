# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class BarcodePage
  attr_accessor :barcodes, :table_columns, :table_rows, :unit 
  attr_accessor :filename, :margin_left, :margin_right, :margin_top, :margin_bottom
  attr_accessor :nolabel, :page_width, :page_height
  attr_accessor :encoding #EAN 39 UPC ISBN 128-B 128-C etc
  attr_accessor :barcode_width,:bardcode_height
  def create
    args = []
    codes = '-c -b ' + @barcodes.join(' -b ')
    args << codes
    table = "-t #{@table_columns}x#{@table_rows}+#{@margin_bottom}+#{@margin_right}-#{@margin_top}"
    args << table
    enc = "-e #{@encoding}"
    args << enc
    if @barcode_width and @barcode_height then
      geometry = "-g #{@barcode_width}x#{@barcode_height}"
      args << geometry
    else
      geometry = ''
    end
    if @unit then
      unit = "-u #{@unit}"
      args << unit
    end
    out = "-o #{@filename}"
    args << out
    cmd = "barcode " + args.join(" ")
    # puts cmd
    system(cmd)
  end
  def table=(h)
    @margin_top = h[:top]
    @margin_left = h[:left]
    @margin_right = h[:right]
    @margin_bottom = h[:bottom]
    @table_columns = h[:cols]
    @table_rows = h[:rows]
  end
end
