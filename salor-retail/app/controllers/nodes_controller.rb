# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
require 'yaml'
YAML::ENGINE.yamler = 'syck'
class NodesController < ApplicationController
  # {START}
  include SalorBase
  # GET /nodes
  # GET /nodes.xml
  def send_msg
    req = Net::HTTP::Post.new('/nodes/receive', initheader = {'Content-Type' =>'application/json'})
    node = Cue.find_by_id(params[:id])
    if node then
      url = uri.parse(node.url)
      req.body = node.payload
      log_action "sending single msg #{node.id}"
      req2 = net::http.new(url.host, url.port)
      response = req2.start {|http| http.request(req) }
      response_parse = json.parse(response.body)
      log_action("received from node: " + response.body)
      node.update_attribute :is_handled, true
    end
    redirect_to request.referer
  end

  def receive_msg
    msg = Cue.find_by_id(params[:id])
    p = SalorBase.symbolize_keys(JSON.parse(msg.payload))
    @node = Node.where(:sku => p[:node][:sku]).first
    if @node then
      @node.handle(p)
    else
      raise "NoNodeFound(#{p[:node][:sku]})"
    end
    redirect_to request.referer
  end
  def index
    @nodes = Node.scopied

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @nodes }
    end
  end

  # GET /nodes/1
  # GET /nodes/1.xml
  def show
    @node = Node.scopied.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node }
    end
  end

  # GET /nodes/new
  # GET /nodes/new.xml
  def new
    @node = Node.scopied.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @node }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.scopied.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.xml
  def create
    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        @node.broadcast_add_me
        Cue.send_all_pending
        format.html { redirect_to(@node, :notice => 'Node was successfully created.') }
        format.xml  { render :xml => @node, :status => :created, :location => @node }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.xml
  def update
    @node = Node.scopied.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html { redirect_to(@node, :notice => 'Node was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.xml
  def destroy
    @node = Node.scopied.find(params[:id])
    @node.kill

    respond_to do |format|
      format.html { redirect_to(nodes_url) }
      format.xml  { head :ok }
    end
  end
  def receive
    begin
    SalorBase.log_action("NodesController","Starting Receive action")
    if params[:node] then
      SalorBase.log_action("NodesController","looking for node")
      @node = Node.where(:sku => params[:node][:sku]).first
      if @node then
        SalorBase.log_action("NodesController","node found, handling")
        n = Cue.new(:source_sku =>params[:node][:sku], :destination_sku => params[:target][:sku],:to_receive => true, :payload => request.body.read)
        n.save
        #render :json => @node.handle(SalorBase.symbolize_keys(JSON.parse(request.body.read))).to_json and return
        render :json => {:success => true}.to_json and return
      else
        SalorBase.log_action("NodesController","Node #{params[:node][:sku]} Could Not Be Found")
        render :json => {:error => "Node could not be found"}.to_json
      end
    else
      SalorBase.log_action("NodesController","no node specified")
      render :json => {:error => "No Node"}.to_json
    end
    rescue => e
      render :text => "Error:" + e.message + e.backtrace.join("\n")
    end
  end
  # {END}
end
