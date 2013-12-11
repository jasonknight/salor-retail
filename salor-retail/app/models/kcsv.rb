# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Kcsv
  def initialize(file, options)
#     raise file.class.inspect
    @file = file.rewind.read.split("\n") if file.class == File or file.class == ActionDispatch::Http::UploadedFile
    @file = file.split("\n") if file.class == String
    @file ||= file 
    options[:separator] ||= ";"
    @options = options
    @separator = options[:separator]
    options[:header] == true ? @headers = parse_header_line(0) : @headers = false
    @children = []
    @accepted_headers = options[:accepted_headers]
    parse
  end
	
  def parse
    i = 0
    @file.each do |line|
      if line == "" then
        i += 1
        next
      end
      #looping through each line of the file
      if i > 0 then # we are past the first line
        x = 0 #we set the index for our position in the headers.
        if line.include? "#HEADERS" then
          @headers = parse_header_line(i)
          i += 1
          next
        end
        i += 1
        row = {} #the row
        if not line.include?(@separator) then #Here we check to see if it is a single column
          row[@headers[x][0]] = clean(line) if not @headers[x].nil?
          row[x] = clean(line) if @headers[x].nil?
        else #we have multiple columns
          line.split(@separator).each do |column|
            #now we need to know if we have headers
            if !@headers.nil? then
              row[@headers[x][0]] = clean(column) if not @headers[x].nil?
            else
              row[x] = clean(column)
            end
             x = x + 1
          end
        end
        @children << row
      else
        i = i + 1 #just there to skipp the first line
      end
    end
    return true
	end
	
	def to_a
          @children
	end
	
  protected
  def clean(string)
    string = string.gsub('"','').strip
    tmp = string.downcase
    if tmp == 'true' then
      return true
    elsif tmp == 'false' then
      return false
    elsif tmp == 'nil' then
      return nil
    elsif tmp == 'null' then
      return nil
    end
    return string
  end
  def parse_header_line(index)
    headers = []
    accepted_headers = @accepted_headers
    line = @file[index]
    x = 0
    # puts @separator
    if not line.include?(@separator) then
      headers << [clean(line),x]
      #headers << [x,x] if not accepted_headers.include? clean(line)
    else
      line.split(@separator).each do |col|
        next if col == "#HEADERS"
        headers << [clean(col).strip.to_sym,x]
        x = x + 1
      end
    end
    return headers
  end
end
