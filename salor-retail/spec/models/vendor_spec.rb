require 'spec_helper'
describe Vendor do
  context "when creating a vendor" do
    it "should have a user" do
      vendor = Factory(:vendor)
      vendor.user.should be
    end # should have a user
  end
  context "when using multicurrency mode" do
    vendor = Factory(:vendor, :multi_currency => true)
    vendor.multi_currency.should == true
  end # when using multicurrency mode
end
