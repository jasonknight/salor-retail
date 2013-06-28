# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
class History < ActiveRecord::Base
  # {START}
  belongs_to :owner, :polymorphic => true
  belongs_to :model, :polymorphic => true
  include SalorBase
  include SalorModel
  include SalorScope
  before_create :set_fields
  def set_fields
    if self.owner_id.nil? then
      self.owner = @current_user
    end
    self.url = $Request.url if $Request and not self.url
    self.params = $Params.to_json if $Params
    self.ip = $Request.ip if $Request
  end
  def self.record(action,object,sen=5,url=nil)
    # sensitivity is from 5 (least sensitive) to 1 (most sensitive)
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
  def self.direct(url,model,params,action_taken,changes_made)
      h = History.new
      h.url = url
      h.params = params
      h.model = model
      h.action_taken = action_taken
      h.changes_made = changes_made
      if not h.save then
        raise h.errors.messages.inspect
      end
  end
  # {END}
end
