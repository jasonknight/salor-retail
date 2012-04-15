require 'spec_helper'

describe "Employes" do
  before(:each) do
    @user = Factory :user, :password => "31202023287"
    @vendor = Factory :vendor, :user => @user
    @cash_register = Factory :cash_register, :vendor => @vendor
    @tax_profile = Factory :tax_profile, :user => @user
    @category = Factory :category, :vendor => @vendor
    GlobalData.salor_user = @user
    GlobalData.vendor = @vendor
    GlobalData.vendor_id = @vendor.id
  end
 describe "GET /employess/login" do
  it "should log you in when visiting with a valid code" do
    visit "/employees/login?code=31202023287" 
    page.should have_content("vendors")
  end
 end
end
