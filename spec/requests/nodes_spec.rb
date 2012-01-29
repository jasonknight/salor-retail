require 'spec_helper'

describe "Nodes" do
  before(:each) do
    @user = Factory :user
    @vendor = Factory :vendor, :user => @user
    @cash_register = Factory :cash_register, :vendor => @vendor
    @tax_profile = Factory :tax_profile, :user => @user
    @category = Factory :category, :vendor => @vendor
    GlobalData.salor_user = @user
    GlobalData.vendor = @vendor
    GlobalData.vendor_id = @vendor.id
    @remote1 = Mechanize.new
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
  end
  def create_local_node(user,name,sku,type,is_self=false)
      visit nodes_path
      click_link "New Node"
      within("#new_node") do
        fill_in "node[name]", :with => name
        fill_in "node[sku]", :with => sku
        fill_in "node[token]", :with => sku
        fill_in "node[node_type]", :with => type
        check "node[is_self]" if is_self
        click_button "Create Node"
      end
  end

 describe "GET /nodes" do
   it "should login successfully and see the nodes page of the test server" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      login_user @user
      visit nodes_path
      page.body.include?("New Node").should == true
    end
    it "should should login successfully to the remote server" do
    end
  end
  describe "creatings a new local node" do
    it "should create a master node and a remote node" do
      login_user @user
      create_local_node(@user,"Master I Created", "MASTER", "Push",true)
      page.body.include?("Master I Created").should == true
      create_local_node(@user,"Salor.com", "SALOR", "Pull",false)
      page.body.include?("Salor.com").should == true
      Node.count.should == 2
    end
  end
end
