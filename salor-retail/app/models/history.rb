# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class History < ActiveRecord::Base
  belongs_to :user
  belongs_to :model, :polymorphic => true
  include SalorBase
  include SalorScope
  
  before_create :set_fields
  
  def set_fields
    self.url = $REQUEST.url if $REQUEST and not self.url
    self.params = $PARAMS.to_json if $PARAMS
    self.ip = $REQUEST.ip if $REQUEST
    self.vendor_id = $VENDORID
    self.company_id = $COMPANYID
    self.user_id = $USERID
  end
  
  def self.record(action, object, sen=5, url=nil)
    h = History.new
    h.url = url
    h.sensitivity = sen
    h.model = object if object
    h.action_taken = action
    if object and object.respond_to? :changes then
      h.changes_made = object.changes.to_json
    end
    h.save
  end
end
