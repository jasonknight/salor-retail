# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
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
