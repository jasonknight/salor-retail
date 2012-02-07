require 'spec_helper'

describe Node do
  before(:each) do 
    @user = Factory :user
    @user2 = Factory :user2, :username => "another user", :email => "another@salor.com"
    @vendor = Factory :vendor, :user => @user2
    GlobalData.salor_user = @user
    GlobalData.vendor = @vendor
    GlobalData.vendor_id = @vendor.id
    GlobalData.salor_user.get_meta.vendor_id = @vendor.id
    @vendor2 = Factory :vendor, :user => @user2
    @cash_register = Factory :cash_register, :vendor => @vendor
    @tax_profile = Factory :tax_profile, :user => @user
    @category = Factory :category, :vendor => @vendor
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @mnode = Factory :node, :vendor => @vendor
    @snode = Factory :node, :node_type => 'pull', :is_self => true, :vendor => @vendor2, :name => "Slave",:sku => "SLAVE", :token => "SLAVE"
    item = @item.clone
    item.base_price = 44.50
    @params = {
      :node => {
        :sku => "MASTER",
        :token => "MASTER"
      },
      :target => {
        :sku => @snode.sku,
        :token => @snode.token
      },
      :record => @mnode.all_attributes_of(@item)
    }
    @params2 = {
      :node => {
        :sku => "MASTER",
        :token => "MASTER"
      },
      :target => {
        :sku => @snode.sku,
        :token => @snode.token
      },
      :record => @mnode.all_attributes_of(@tax_profile)
    } 
    @params3 = {
      :node => {
        :sku => "MASTER",
        :token => "MASTER"
      },
      :target => SalorBase.symbolize_keys(@snode.attributes),
      :message => "AddMe"
    }
    @params4 = {
      :node => {
        :sku => "MASTER",
        :token => "MASTER"
      },
      :target => {
        :sku => @snode.sku,
        :token => @snode.token
      },
      :record => @mnode.all_attributes_of(@category)
    } 

    

  end
  def create_pc_items
    puts "Executing?"
    @carton = Factory :item, :quantity => 1,:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @carton.update_attribute(:packaging_unit,1)
    @pack = Factory :item, :quantity => 10,:sku => "PACK",:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @pack.update_attribute(:packaging_unit,10)
    @piece = Factory :item, :quantity => 20,:sku => "PIECE",:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @piece.update_attribute(:packaging_unit,20)
    @piece.parent_sku = @pack.sku
    @pack.parent_sku = @carton.sku
  end
  def symbolize_keys arg
    case arg
    when Array
      arg.map { |elem| symbolize_keys elem }
    when Hash
      Hash[
        arg.map { |key, value|  
          k = key.is_a?(String) ? key.to_sym : key
          v = symbolize_keys value
          [k,v]
        }]
    else
      arg
    end
  end
  context "when receiving a json object" do
    it "should have valid params decoded from JSON" do
      @params[:target].class.should == Hash
      @params[:target][:sku].should == @snode.sku
      @params[:record][:class].should == "Item"
    end # should have valid params
    it "has a method to handle the request" do
      @mnode.handle(@params)
    end # has a method to handel the request
    it "verifies that the target node exists" do
      @mnode.handle(@params)
      @mnode.verify?.should be_true
    end # verifies that the target node exists
    it "should parse the params and convert the special relations" do
      @mnode.handle(@params)
      @mnode.parse(@mnode.record).key?(:category_sku).should be_false
      @mnode.parse(@mnode.record)[:tax_profile_sku].should == @tax_profile.sku
    end # should parse the params and convert the special relations
    it "should have an item klass" do
      @params[:record][:base_price] = 44.50
      @mnode.record[:base_price].should_not == @item.base_price
      @mnode.handle(@params)
      @mnode.klass.should == Item
      @mnode.inst.should == @item
      @item.reload.base_price.should == 44.50
      @mnode.target.vendor.should == @vendor2
      @vendor2.items.first.should == @item
    end # should have an item klass
    it "should not die when the target is bad" do
      @params[:target][:token] = "BADTOKEN"
      @mnode.handle(@params)
      @mnode.verify?.should be_false
      @vendor2.items.length.should == 0
    end # should not die when the target is bad
    it "should should prepare a model for sending and return a hash" do
      @mnode.prepare(@item,@snode).class.should == Hash
    end
  end # when receiving a json object
  context "when preparing a record to send" do
    it "should contain a target key, with the correct token" do
      hash = @mnode.prepare(@item,@snode)
      hash[:target][:token].should == @snode.token
      hash[:target][:sku].should == @snode.sku
    end
    it "should attach itself as the node in the hash" do
      hash = @mnode.prepare(@item,@snode)
      hash[:node][:token].should == @mnode.token
      hash[:node][:sku].should == @mnode.sku
    end
    it "should verify? the model sent" do
      @mnode.prepare(@item,@snode)
      @mnode.verify?.should == true
    end
    it "should verify categories too..." do
      @mnode.prepare(@category,@snode)
      @mnode.verify?.should_not == false
    end
    it "should return true or false to see if record has been changed" do
      @item.save!
      @mnode.verify_changed?(@item).should == false 
    end
    it "should return true when the model has been changed" do
      @item.base_price = 10.95
      @mnode.verify_changed?(@item).should == true
    end
    it "should produce a record hash with only the changed attributes" do
      @item.base_price = 10.95
      @mnode.update_hash(@item)
      @mnode.hash[:record].keys.include?(:base_price).should == true
    end
    it "should return a json payload for the current hash" do
      @item.base_price = 10.95
      @mnode.prepare(@item,@snode)
      @mnode.payload.class.should == String
      @mnode.payload.include?("base_price").should == true
      @mnode.payload.include?("10.95").should == true
    end
    it "should ignore useless attributes" do
      @item.updated_at = Time.now
      @mnode.prepare(@item,@snode)
      @mnode.hash.keys.include?(:updated_at).should == false
    end
    it "should handle tax_profiles as well" do
      @vendor2.tax_profiles.length.should == 0
      @mnode.handle(@params2)
      @mnode.klass.should == TaxProfile
      @mnode.inst.should == @tax_profile 
      @mnode.target.vendor.should == @vendor2
      # @vendor2.tax_profiles.first.should == @tax_profile
    end
    it "should handle categories as well" do
      @vendor2.categories.length.should == 0
      @mnode.handle(@params4)
      @mnode.klass.should == Category
      @mnode.inst.should == @category 
      @mnode.target.vendor.should == @vendor2
      # @vendor2.tax_profiles.first.should == @tax_profile
    end

    it "should handle special message cases" do
      @params3[:target][:sku] = "NEWSLAVE"
      @mnode.request = mock(Net::HTTP)
      @mnode.request.should_receive(:start).at_least(:twice)
      @mnode.handle(@params3)  
      @target = Node.where(:sku => @params3[:target][:sku], :token => @params3[:target][:token]).first.should be
    end
  end
end
