require 'spec_helper'
describe GlobalData do
  context "when unpopulated" do
    it "should not have a salor_user" do
#GlobalData.salor_user.should_not be   
    end # should not have a salor_user
  end
  context "when populated" do
    it "should have a salor_user" do
      user = Factory.build(:user)
      GlobalData.salor_user = user
      GlobalData.salor_user.should be
    end # should have a salor_user
    it "should refresh" do
      GlobalData.salor_user.should be
      GlobalData.refresh
      GlobalData.salor_user.should_not be
    end # should refresh
  end
end
