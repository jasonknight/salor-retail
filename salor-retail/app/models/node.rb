# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Node < ActiveRecord::Base
  include SalorBase
  include SalorScope
  include SalorModel
  belongs_to :vendor
  before_create :set_model_user
  attr_accessor :record, :target, :klass, :inst, :hash, :params, :request
  @@a = ["Button", "Category","Customer","Item","TaxProfile","LoyaltyCard"]
  def node_type=(t)
    write_attribute(:node_type,t.downcase)
  end
  def handle(params)
    log_action "Node receiving object"
    begin
    if params.class == String then
      params = JSON.parse(params)
    end
    @md5 = Digest::SHA2.hexdigest("#{params[:record].to_json}")
    @params = SalorBase.symbolize_keys(params)
    @target = Node.where(:sku => @params[:target][:sku], :token => @params[:target][:token]).first
    if @params[:message] then
      log_action "Handling message param"
      if not handle_message(@params) then
        return # i.e. if handle_message returns false, then we just exit out and hope everything went according to plan.
      end
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
      @current_user = @target.vendor.user
      GlobalData.vendor = @target.vendor
      GlobalData.vendor_id = @target.vendor.id
      if @record.class == Array then
        @record.each do |rec|
          new_record = parse(rec)
          create_or_update_record(new_record)
        end
      else
        new_record = parse(@record)
        create_or_update_record(new_record)
      end
    else
      # puts "Failed to verify"
      log_action "node failed to verify"
    end
    rescue
      log_action "An error occurred: " + $!.inspect
      log_action $!.backtrace.join("\n")
      log_action Kernel.caller.join("\n")
    end
  end
  def attributes_of_item(models,model)
    attrs = all_attributes_of(model)
    if model.parts.any?
      pskus = []
      model.parts.each do |part|
        models << all_attributes_of(part)
        pskus << part.sku
      end
      attrs[:part_skus] = pskus
    end
    if item.category and item.category.sku.nil? then
      item.category.set_sku
      item.category.save
    end
    attrs[:category_sku] = model.category.sku if model.respond_to? :category and model.category.respond_to? :sku
    if model.parent then
      models << all_attributes_of(model.parent)
      attrs[:parent_sku] = model.parent.sku
    end
    models << attrs
    return models
  end
  def handle_message(params)
    if params[:message] == "AddMe" and @target.nil? and params[:target][:node_type].downcase == 'pull' then
      @target = Node.new(params[:target])
      @target.is_self = false
      @target.vendor_id = self.vendor_id
      @target.hidden = 0
      @target.save
      @target.update_attribute :hidden,0
      # now we need to do an initial sync of tax profiles, buttons, categories
      # and customers
      @hash = {}
      @hash.merge!({:target => {:token => @target.token, :sku => @target.sku}})
      @hash.merge!({:node => {:token => self.token, :sku => self.sku}, :message => "Sync"})
      [Category,TaxProfile,Item,Button,Customer].each do |klass|
        x = 0 # we want to send them in small blocks
        models = []
        klass.scopied.all.each do |model|
          if model.class == Item and model.parts.any? then
            models = attributes_of_item(models,model)
          else
            models << all_attributes_of(model)
          end
          x = x + 1
          if x > 20 then
            @hash[:record] = models
            send!
            x = 0
            models = []
          end
        end
        @hash[:record] = models
        send! if models.any? # finally, send off the last amount
      end
      return false #just quit out
    else
      log_action "You cannot create an identical node." + params.inspect
      return true # just quit out
    end
    return true # I.E. handle the record object as normal
  end
  def create_or_update_record(new_record)
    # puts "Creating record"
    log_action "CREATE OR UPDATE RECORD"
    if new_record[:loyalt_card_sku] then
      lc = LoyaltyCard.find_by_sku new_record[:loyalty_card_sku]
      if lc then
        @inst = lc.customer
      end
    else
      @inst = @klass.find_by_sku new_record[:sku]
    end
    if @inst then 
      # puts "Updating record"
      if @target.send("accepts_#{@inst.class.table_name}") then
        @inst.update_attributes(new_record)
        log_action "UPDATING ATTRS OF #{@inst.class} with id of #{@inst.id}"
      else
        log_action "REJECTING #{@inst.class}"
      end
    else
      # puts "Creating new record"
      @inst = @klass.new(new_record)
      if @target.send("accepts_#{@inst.class.table_name}") then
        log_action "CREATING A NEW RECORD"
        if @inst.save then
          log_action "Saved item to database " + @inst.inspect
        else
          log_action "There were errors..."
          @inst.errors.full_messages.each do |msg|
            log_action msg
          end
        end
      else
        log_action "REJECTING #{@inst.class}"
      end
    end
  end
  def parse(record)
    @klass = Kernel.const_get(record[:class])
    new_record = record.clone
    log_action "Considering: " + new_record.inspect
    if record.key? :category_sku then
      c = Category.find_by_sku(record[:category_sku])
      new_record[:category_id] = c.id
      new_record.delete(:category_sku)
      c.update_attribute :vendor_id, @target.vendor_id
    end
    if record.key? :tax_profile_sku then
      if not TaxProfile.where(:sku => record[:tax_profile_sku]).any? then
        tp = TaxProfile.new(:name => "AutoGenerated", :sku => record[:tax_profile_sku], :user_id => @target.vendor.user_id)
        tp.save
        new_record[:tax_profile_id] = tp.id
        new_record.delete(:tax_profile_sku)
      end
    end
    new_record.delete(:class)
    new_record[:vendor_id] = @target.vendor_id if klass != LoyaltyCard
    new_record
  end
  def verify?
    if @hash then
      if not verify_target_node? then
        return false
      else
        return true
      end
    end
    allowed_classes = @@a 
    if @record.class == Array then
      @record.each do |rec|
        if not allowed_classes.include? rec[:class] then
          log_action "Wrong class in array..."
          return false
        end
      end
    else
      if not allowed_classes.include? @record[:class] then
        log_action "Wrong class: " + @record.to_s
       return false
      end
    end
    if @target.nil? then
      log_action "Target is nil..."
      return false
    end
    return true
  end
  def prepare(model,target,force=false)
    return {} if not @@a.include? model.class.to_s
    @target = target
    @record = model
    @hash = {}
    @hash.merge!({:target => {:token => @target.token, :sku => @target.sku}})
    @hash.merge!({:node => {:token => self.token, :sku => self.sku}})
    if not force then
      @hash[:record] = update_hash(@record)
    else
      @hash[:record] = all_attributes_of(@record)
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
      record[k.to_sym] = v[1] unless iggy?(k,item)
    end
    if item.respond_to? :sku and item.sku.nil? then
      item.set_sku if item.respond_to? :set_sku
    end
    record[:sku] = item.sku if item.respond_to? :sku
    record[:tax_profile_sku] = item.tax_profile.sku if item.respond_to? :tax_profile
    record[:category_sku] = item.category.sku if item.respond_to? :category and item.category.respond_to? :sku
    record[:class] = item.class.to_s
    record[:name] = item.name if item.respond_to? :name
    if item.class == Customer then
      if item.sku.blank? or item.sku.nil? then
        item.sku = "ICANTBELIEVETHISSHIT"
      end
      record[:loyalty_card_sku] = item.loyalty_card.sku
      record[:loyalty_card_points] = item.loyalty_card.points
    end
    record
  end
  def iggy?(attr,model)
    item_ignore = ["tax_profile_id","shipper_id","location_id","vendor_id", "created_at", "updated_at","category_id","child_id"]
   if item_ignore.include?(attr.to_s) and
      return true
    end
  end
  def all_attributes_of(item)
    if item.class == Item then
      if item.category and item.category.sku.nil? then
        item.category.set_sku
        item.category.save
      end
    end
    record = {:class => item.class.to_s}
    item.attributes.each do |k,v|
      record[k.to_sym] = v if not iggy?(k,item)
    end
    if item.respond_to? :sku and item.sku.nil? then
      item.set_sku if item.respond_to? :set_sku
    end
    record[:sku] = item.sku if item.respond_to? :sku
    record[:tax_profile_sku] = item.tax_profile.sku if item.respond_to? :tax_profile
    record[:category_sku] = item.category.sku if item.respond_to? :category and item.category.respond_to? :sku
    record[:class] = item.class.to_s
    if item.class == Customer then
      record[:loyalty_card_sku] = item.loyalty_card.sku
      record[:loyalty_card_points] = item.loyalty_card.points
    end
    record
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
      log_action puts "Could not verify on send..."
      return nil
    end
    send!   
  end
  # need to rethinkt his part, see handle_message above, cloning 
  # is currently done at that point...
  def clone_to_node(item,target)
    prepare(item,target,true)
    if not verify? then
      log_action "clone_to_node: Could not verify on send..."
      return nil
    end
    send!  
  end
  #
  def send!
    # req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    # url = URI.parse(@target.url)
     
    @md5 = Digest::SHA2.hexdigest("#{@hash[:record].to_json}")
    if NodeMessage.where(:dest_sku => @target.sku, :mdhash => @md5).any? then
      log_action "I've sent this before" + @hash[:record].to_json 
      return
    elsif NodeMessage.where(:source_sku => @target.sku, :mdhash => @md5).any? then
      log_action "Node already knows about changes"
      return
    else
      n = NodeMessage.new(:source_sku => self.sku, :dest_sku => @target.sku, :mdhash => @md5)
      n.save
    end
    n = Cue.new(:source_sku => self.sku, :destination_sku => @target.sku, :url => @target.url, :to_send => true, :payload => self.payload)
    n.save
    log_action "Cue created with attributes: #{n.attributes.to_json}"
    # req.body = self.payload
    #log_action "Sending: " + req.body.inspect
#   @request ||= Net::HTTP.new(url.host, url.port)
#    response = @request.start {|http| http.request(req) }
    # puts response.body
#   response
  end
  def self.flush
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
   Cue.where(:to_send => true).each do |node|
      url = URI.parse(node.url)
      req.body = node.payload
      SalorBase.log_action "Node","sending single msg #{node.id}"
      req2 = Net::HTTP.new(url.host, url.port)
      response = req2.start {|http| http.request(req) }
      response_parse = JSON.parse(response.body)
      SalorBase.log_action("Node","received from node: " + response.body)
      node.update_attribute :is_handled, true
   end # end cue.where to_send

   Cue.where(:to_receive => true).each do |msg|
      p = SalorBase.symbolize_keys(JSON.parse(msg.payload))
      node = Node.where(:sku => p[:node][:sku]).first
      if node then
        node.handle(p)
      end
   end # end cue.where to_receive
  end
#
  def broadcast_add_me
    return if self.is_self == true
    node = Node.scopied.where(:is_self => true).first
    return if node.nil?
    params = {
      :node => {
        :sku => self.sku,
        :token => self.token
      },
       # this is a special case, where the target is the record...
      :target => SalorBase.symbolize_keys(node.attributes),
      :message => "AddMe"
    }
    return if not params[:target]

    @md5 = Digest::SHA2.hexdigest("#{@hash[:record].to_json}")
    
    n = Cue.new(:to_send => true,:url => self.url, :destination_sku => self.sku, :source_sku => self.sku, :payload => params.to_json) 
    n.save
    return
    self.update_attribute :is_busy, true
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    url = URI.parse(self.url)
    req.body = params.to_json
    @request ||= Net::HTTP.new(url.host, url.port)
    response = @request.start {|http| http.request(req) }
    # puts response.body
    self.update_attribute :is_busy, false
    response
  end
end
