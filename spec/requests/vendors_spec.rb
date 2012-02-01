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
    visit "/employees/login?code=31202023287" 
    @vendor.salor_configuration.update_attribute :salor_printer, false
    @cash_register.update_attribute :vendor_id, @vendor.id
    visit "/orders/new?vendor_id=#{@vendor.id}&cash_register_id=#{@cash_register.id}"
    page.html.include?("SalorPrinter.printURL").should == false
    visit "/vendors/#{@vendor.id}/edit"
    check "vendor[salor_configuration_attributes][salor_printer]"
    click_button I18n.t("helpers.submit.save")
    page.html.include?("successfully updated.")
    @vendor.reload.salor_configuration.salor_printer.should == true
    visit "/orders/new?vendor_id=#{@vendor.id}&cash_register_id=#{@cash_register.id}"
    page.should have_content("SalorPrinter")
  end
 end
end
