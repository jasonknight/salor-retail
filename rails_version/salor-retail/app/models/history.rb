# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class History < ActiveRecord::Base
  include SalorBase
  include SalorScope
  
  belongs_to :user
  belongs_to :vendor
  belongs_to :company
  belongs_to :model, :polymorphic => true
  
  validates_presence_of :vendor_id, :company_id
  
  def self.record(action, object, sen=5, url=nil)
    h = History.new
    h.vendor = object.vendor
    h.company = object.company
    h.user_id = $USERID
    h.url = url
    h.url ||= $REQUEST.url if $REQUEST
    h.ip = $REQUEST.ip if $REQUEST
    h.params = $PARAMS.to_json if $PARAMS
    h.sensitivity = sen
    h.model = object if object
    h.action_taken = action
    if object and object.respond_to? :changes then
      h.changes_made = object.changes.to_json
    end
    h.save!
  end
end
