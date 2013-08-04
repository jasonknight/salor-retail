# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class Receipt < ActiveRecord::Base
  belongs_to :user
  belongs_to :vendor
  belongs_to :company
  belongs_to :order
  belongs_to :cash_register
  belongs_to :drawer
  
  validates_presence_of :vendor_id, :company_id

  
  def to_html
    i = 0
    html = ''
    elem = false
    center = false
    h1 = false
    bold = false
    the_content = self.content.to_s.encode("UTF-8", {:invalid => :replace, :replace => '', :undef => :replace})
    puts "Receipt content is: [[ #{the_content} ]]"
    begin
      if the_content[i] == "\e" then
        b1,b2,b3 = [the_content[i+1],the_content[i+2],the_content[i+3]]
        puts "0x#{b1.unpack('H*')[0]} + 0x#{b2.unpack('H*')[0]}"
        if b1 == "!" and b2 == "\x18" then
          i += 1
          html += "<span class=\"tall-bold\">"
          bold = true
        elsif b1 == "@" then
          # initialize, so move on
          puts "init"
          i += 1
        elsif b1 == "p" then
          puts "pulse"
          i += 3
        elsif b1 == "\x61" then
          #justification
          if b2 == "\x01" then
            puts "center"
            html += "<center>"
            center = true
            i += 1
          elsif b2 == "\x00" then
            puts "left"
            if center
              html += "</center>"
              center = false
            end
            i += 1
          end
        elsif b1 == "\x21" then
          puts "select print mode"
          if b2 == "\x00" then
            puts "normal font"
            if bold then
              html += "</span>"
              bold = false
            end
            if center then
              html += "</center>"
            end
          elsif b2 == "\x38" then
            puts "h1"
            h1 = true
            html += "<h1>"
            i += 1
          elsif b2 == "\x01" then
            puts "9x17 selected"
            if h1
              html += "</h1>" 
              h1 = false
            end
            if center then
              html += "</center>"
              center = false
            end
          end
          i += 1
        end
        puts "-----"
      elsif the_content[i] == "\n" then
        if h1 then
          html += "</h1>"
          h1 = false
        end
        html += "</br>"
      elsif the_content[i] == "?" then
        if h1 then
          html += "</h1>"
          h1 = false
        end
        html += '-'
      elsif the_content[i] == " " then
        html += "&nbsp;"
      else
        html += the_content[i] 
        
      end
      i += 1
      
    end while i < the_content.length
    return html
  end
end
