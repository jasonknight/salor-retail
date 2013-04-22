# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class Receipt < ActiveRecord::Base
  belongs_to :employee
  belongs_to :vendor
  belongs_to :order
  def to_html
    i = 0
    html = ''
    elem = false
    center = false
    h1 = false
    bold = false
    begin
      if self.content[i] == "\e" then
        b1,b2,b3 = [self.content[i+1],self.content[i+2],self.content[i+3]]
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
      elsif self.content[i] == "\n" then
        if h1 then
          html += "</h1>"
          h1 = false
        end
        html += "</br>"
      elsif self.content[i] == "?" then
        if h1 then
          html += "</h1>"
          h1 = false
        end
        html += '-'
      elsif self.content[i] == " " then
        html += "&nbsp;"
      else
        html += self.content[i] 
      end
      i += 1
      
    end while i < self.content.length
    return html
  end
end
