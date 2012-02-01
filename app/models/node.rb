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
class Node < ActiveRecord::Base
  include SalorBase
  include SalorScope
  include SalorModel
  belongs_to :vendor
  before_create :set_model_owner
  after_create :broadcast_add_me
  attr_accessor :record, :target, :klass, :inst, :hash, :params
  @@a = ["Item","TaxProfile","Discount"]
  def handle(params)
    log_action "Node receiving object"
    if params.class == String then
      params = JSON.parse(params)
    end
    @md5 = Digest::SHA2.hexdigest("#{params}")
    @params = SalorBase.symbolize_keys(params)
    @target = Node.where(:sku => @params[:target][:sku], :token => @params[:target][:token]).first
    if @params[:message] then
      log_action "Handling message param"
      handle_message(@params)
    end
    if not @params[:record] then
      log_action "Params has no record attached."
      return
    end
    @record = @params[:record]
    if verify? then
        if NodeMessage.where(:dest_sku => @target.sku, :mdhash => @md5).any? then
          log_action "I've played this before"
          return
        else
          n = NodeMessage.new(:source_sku => self.sku, :dest_sku => @target.sku, :mdhash => @md5)
          n.save
        end
      GlobalData.salor_user = @target.vendor.user
      GlobalData.vendor = @target.vendor
      GlobalData.vendor_id = @target.vendor.id
      new_record = parse(@record)
      create_or_update_record(new_record)
    else
      # puts "Failed to verify"
      log_action "node failed to verify"
    end
  end
  def handle_message(params)
    if params[:message] == "AddMe" and @target.nil? and params[:target][:node_type].downcase == 'pull' then
      @target = Node.new(params[:target])
      @target.is_self = false
      @target.save
    else
      log_action "You cannot create an identical node." + params.inspect
    end
  end
  def create_or_update_record(new_record)
    # puts "Creating record"
    log_action "CREATE OR UPDATE RECORD"
    @inst = @klass.find_by_sku new_record[:sku]
    if @inst then 
      # puts "Updating record"
      @inst.update_attributes(new_record)
      log_action "UPDATING ATTRS OF #{@inst.class} with id of #{@inst.id}"
    else
      # puts "Creating new record"
      log_action "CREATING A NEW RECORD"
      @inst = @klass.new(new_record)
      if @inst.save then
        log_action "Saved item to database " + @inst.inspect
      end
    end
  end
  def parse(record)
    @klass = Kernel.const_get(record[:class])
    new_record = record.clone
    if record.key? :category then
      c = Category.find_or_create_by_name(record[:category])
      new_record[:category_id] = c.id
      new_record.delete(:category)
      c.update_attribute :vendor_id, @target.vendor_id
    end
    if record.key? :location then
      c = Location.find_or_create_by_name(record[:location])
      new_record[:location_id] = c.id
      new_record.delete(:location)
      c.update_attribute :vendor_id, @target.vendor_id
    end
    if record.key? :tax_profile_sku then
      if not TaxProfile.where(:sku => record[:tax_profile_sku]).any? then
        tp = TaxProfile.new(:name => "AutoGenerated", :sku => record[:tax_profile_sku], :user_id => @target.vendor.user_id)
        tp.save
      end
    end
    new_record.delete(:class)
    new_record[:vendor_id] = @target.vendor_id
    new_record
  end
  def verify?
    if @hash then
      if not verify_target_node? then
        return false
      end
    end
    allowed_classes = @@a 
    if not allowed_classes.include? @record[:class] and not allowed_classes.include? @record.class.to_s then
      log_action "Wrong class: " + @record[:class].to_s
      return false
    end
    if @target.nil? then
      log_action "Target is nil..."
      return false
    end
    true
  end
  def prepare(model,target,force=false)
    return {} if not @@a.include? model.class.to_s
    @target = target
    @record = model
    @hash = {}
    @hash.merge!({:target => {:token => @target.token, :sku => @target.sku}})
    @hash.merge!({:node => {:token => self.token, :sku => self.sku}})
    if not force then
      update_hash(@record)
    else
      all_attributes_of(@record)
    end
    @hash
  end
  def verify_changed?(model)
    not model.changes.empty?
  end
  def update_hash(item)
    @hash ||= {}
    record = {:class => item.class.to_s}
    item.changes.each do |k,v|
      record[k.to_sym] = v[1]
    end
    record[:sku] = item.sku
    if item.class == Item then
      record[:tax_profile_sku] = item.tax_profile.sku
      record[:name] = item.name
    end
    @hash[:record] = record
    @hash
  end
  def iggy?(attr,model)
    item_ignore = ["tax_profile_id","shipper_id","location_id","vendor_id", "created_at", "updated_at","category_id","child_id"]
    if model.class == Item and item_ignore.include?(attr.to_s) and
      return true
    end
  end
  def all_attributes_of(item)
    @hash ||= {}
    record = {:class => item.class.to_s}
    item.attributes.each do |k,v|
      record[k.to_sym] = v if not iggy?(k,item)
    end
    record[:sku] = item.sku
    if item.class == Item then
      record[:tax_profile_sku] = item.tax_profile.sku
    end
    record[:class] = item.class.to_s
    @hash[:record] = record
    @hash
  end
  def payload
    return @hash.to_json
  end
  def verify_target_node?(target=nil)
    target ||= @target
    return false if target.nil?
    return true
    result = `ping -q -c 3 #{target.url}`
    # puts $?.exitstatus
    if not $?.exitstatus == 0 then
      return false
      target.update_attribute :status, "offline"
    end
    true
  end
  def send_to_node(item,target)
    prepare(item,target)
    if not verify? then
      # puts "Could not verify on send..."
      return nil
    end
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    url = URI.parse(@target.url)
    req.body = self.payload
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    # puts response.body
    response
  end
  def clone_to_node(item,target)
    prepare(item,target,true)
    if not verify? then
      log_action "clone_to_node: Could not verify on send..."
      return nil
    end
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    url = URI.parse(@target.url)
    req.body = self.payload
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    # puts response.body
    response
  end
  def broadcast_add_me
    return if self.is_self == true
    node = Node.scopied.where(:is_self => true).first
    return if node.nil?
    params = {
      :node => {
        :sku => self.sku,
        :token => self.token
      },
      :target => SalorBase.symbolize_keys(node.attributes),
      :message => "AddMe"
    }
    return if not params[:target]
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    url = URI.parse(self.url)
    req.body = params.to_json
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    # puts response.body
    response
  end

end