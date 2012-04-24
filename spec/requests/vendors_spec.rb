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
    GlobalData.cash_register = @cash_register
  end
 describe "editing a vendor" do
  it "should allow you to set salor_printer on the vendor config" do
  end
 end
end
