require 'spec_helper'
describe SalorBase do
  context "when using instance methods" do
    it "should properly convert currency amounts" do
      SalorBase.string_to_float("$23.59").should == 23.59
      SalorBase.string_to_float("USD 22.40").should == 22.40
    end # should not have a salor_user
    it "should properly convert internationalized currency" do
      SalorBase.string_to_float("22,86 EUR").should == 22.86
    end
    it "should convert quantities with a preceision of 3" do
      SalorBase.string_to_float("2.888").should == 2.888 
    end
  end
end
