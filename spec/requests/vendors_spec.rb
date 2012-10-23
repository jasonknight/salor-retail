require 'spec_helper'

describe "Vendors" do
  before(:each) do
    single_store_setup
    sleep(4)
    login_employee("31202053295")
  end
  def click_on(id)
    find(id).click
    sleep(1)
  end
 describe "editing a vendor" do
   it "should allow you to edit the vendor", :js => true, :driver => :selenium  do
    visit "/vendors"
    page.should have_content @vendor.name
    find("#vendor_#{@vendor.id}").click
    sleep(1)
    find("#edit_vendor").click
    fill_in("vendor[name]",:with => "I have edited the name")
    find("#save_button").click
    sleep(2)
    @vendor.reload.name.should == "I have edited the name"
  end
 end
end
