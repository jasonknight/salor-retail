require 'spec_helper'
describe Employee do
  context "when considering user roles" do
    it "should return the correct root" do
      user = Factory :employee
      user.roles << Factory(:manager_role)
      r = user.get_root
      r[:controller].to_s.should == "vendors"
      r[:action].to_s.should == "show"
      r[:id].should == user.vendor_id
    end
    it "should validate all generated codes" do
      File.open("/home/michael/work/salor_valid_keys.csv","r").each_line do |line|
        parts = line.split("\t")
        if SalorBase.check_code(parts[0]) == false then
          raise "Code was invalid..." + parts[0]
        else
          #puts "Valid: " + parts[0]
        end
      end if File.exists?("/home/michael/work/salor_valid_keys.csv")
    end
  end
end
