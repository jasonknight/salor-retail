require 'yaml'
YAML::ENGINE.yamler = 'syck'
class NodesController < ApplicationController
  # GET /nodes
  # GET /nodes.xml
  before_filter :authify, :except => [:receive]
  before_filter :initialize_instance_variables, :except => [:receive]
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
    @node.destroy

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
        render :json => @node.handle(SalorBase.symbolize_keys(JSON.parse(request.body.read))).to_json and return
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
end
