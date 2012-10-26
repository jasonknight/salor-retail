require 'spec_helper'

describe "Orders" do
  before(:each) do
    single_store_setup
    sleep(4)
    login_employee("31202053295")
  end
  it "should not have a translation missing for each of the languages", :js => true, :driver => :selenium  do
    ['en-US','en-GB','de','el','fr','es','ru','pl','hu','cn'].each do |lang|
      @manager.update_attribute(:language, lang)
      [:orders,:vendors,:items, :categories, :locations, :actions, :discounts, :employees].each do |p|
        puts "/#{p}?locale=#{lang}&vendor_id=#{@vendor.id}"
        visit("/#{p}?locale=#{lang}&vendor_id=#{@vendor.id}")
        puts page.body.to_s.scan(/translation missing: #{lang}[\w\.]+/)
        page.body.to_s.include?("translation missing: #{lang}").should == false
        puts "/#{p}/new?locale=#{lang}&vendor_id=#{@vendor.id}"
        if p == :orders then
          visit("/#{p}/new?cash_register_id=#{@cash_register.id}&locale=#{lang}&vendor_id=#{@vendor.id}")
        else
          visit("/#{p}/new?locale=#{lang}&vendor_id=#{@vendor.id}")
        end
        
        puts page.body.to_s.scan(/translation missing: #{lang}[\w\.]+/)
        page.body.to_s.include?("translation missing: #{lang}").should == false
      end # end paths each
      
    end # end langs each
    
  end # end it
  
end