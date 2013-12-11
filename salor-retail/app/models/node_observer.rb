# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

require 'net/http'
require 'uri'

class NodeObserver < ActiveRecord::Observer
  include SalorBase
  
  observe :item,:tax_profile,:button, :customer, :category, :loyalty_card
  def send_json(record)
    snode = Node.scopied.where(:is_self => true).limit(1).first
    if not snode then
      log_action "No Self Node Found"
      return
    end
    if record.class == Customer or record.class == LoyaltyCard then
      child_nodes = Node.scopied.where(:is_self => false,:is_busy => false)
    else
      log_action Node.scopied.where(:is_self => false, :node_type => 'pull', :is_busy => false).to_sql
      child_nodes = Node.scopied.where(:is_self => false, :node_type => 'pull', :is_busy => false)
    end
    log_action "Sending to children: #{child_nodes.length}"
    NodeMessage.where(["created_at < ?", Time.now - 5.minutes]).delete_all
    child_nodes.each do |c|
      log_action "Sending to child: " + c.inspect
      begin
        response = snode.send_to_node(record,c)
      rescue
        log_action $!.inspect
      end
    end
  end
  def after_update(record)
    #log_action "after_update called for: " + record.changes.inspect
    send_json(record)
  end
  def after_create(record)
    #log_action "after_create called for: " + record.changes.inspect
    send_json(record)
  end
end
