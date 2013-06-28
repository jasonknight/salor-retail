# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class PaylifeStructs < ActiveRecord::Base
  include SalorBase
  include SalorScope
  belongs_to :owner, :polymorphic => true
  def set_model_owner
    user = @current_user
    if user then
      self.owner_type = user.class.to_s
      self.owner_id = user.id
      self.cash_register_id = user.cash_register_id
      self.order_id = user.order_id
      self.vendor_id = user.vendor_id
    end
  end
  def paylife_blurb
    text = JSON.parse(self.json)
    if text['sa'] == 'P' then
      pattern = /STX (P)\d\d(\d)(.{40})(.{16})(.{3})(.+) ETX/
      str = self.struct
      match = str.match(pattern)
      parts = match[6].split(" ")
      journal = PaylifeStructs.where("id > '#{self.id}'").limit(1).order('id asc').first
      j_json = JSON.parse(journal.json)
      jts = []
      jt = j_json['text']
      jt ||= ''
      begin
        x = jt.utf8_safe_split(33)
        jts << x[0]
        jt = x[1]
      end while jt.length.to_i >= 33
      jt = jts.join("\n")
      return "#{match[4]}\n#{parts[0]}\n#{parts[2]}\n\n#{jt}"
    end
   
  end
end
