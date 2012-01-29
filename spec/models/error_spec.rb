require 'spec_helper'

describe Error do
  before(:each) do
    @user = Factory :user
    @vendor = Factory :vendor, :user => @user
    GlobalData.salor_user = @user
  end
  it "should have an owner" do
    @error = Error.new(:msg => "Test Error")
    @error.should be
    @error.save
    @error.owner.should == GlobalData.salor_user
  end # should have an owner
  it "should be accessible from the user that created it" do
    @error = Error.new(:msg => "Test Error")
    @error.save
    GlobalData.salor_user.unseen_salor_errors.first.should == @error
  end # should be accessible from the user that created it
  it "should not show up in unseen errors once it is set to seen" do
    @error = Error.new(:msg => "Test Error")
    @error.save
    GlobalData.salor_user.unseen_salor_errors.first.should == @error
    @error.update_attribute(:seen, true)
    GlobalData.salor_user.unseen_salor_errors.should be_empty
  end # should not show up in unseen errors once it is set to seen
end
