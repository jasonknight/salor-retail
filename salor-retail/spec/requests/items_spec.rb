require 'spec_helper'

describe "Items" do
  before(:each) do
    single_store_setup
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
  end
   describe "GET /employess/login" do
      it "should render printr label", :js => true, :driver => :selenium do
         @cash_register.update_attribute(:salor_printer,true)
         @item.should be_valid
         visit "/items/labels?id=#{@item.id}&type=label&user_id=#{@manager.id}&cash_register_id=#{@cash_register.id}"
         page.should have_content(@item.sku)
         @cash_register.update_attribute(:salor_printer,false)
         @cash_register.update_attribute(:thermal_printer,"/tmp/thermal_printer")
         visit "/items/labels?id=#{@item.id}&type=label&user_id=#{@manager.id}&cash_register_id=#{@cash_register.id}"
         File.open("/tmp/thermal_printer",'r') {|f| f.read }.include?(@item.sku).should == true
      end
      it "should render printr sticker label", :js => true, :driver => :selenium do
        @cash_register.update_attribute(:salor_printer,true)
        visit "/items/labels?id=#{@item.id}&type=sticker&user_id=#{@manager.id}&cash_register_id=#{@cash_register.id}"
        page.should have_content(@item.sku)
        @cash_register.update_attribute(:salor_printer,false)
        @cash_register.update_attribute(:sticker_printer,"/tmp/sticker_printer")
        visit "/items/labels?id=#{@item.id}&type=sticker&user_id=#{@manager.id}&cash_register_id=#{@cash_register.id}"
        File.open("/tmp/sticker_printer",'r') {|f| f.read }.include?(@item.sku).should == true
      end
   end
end
