require 'spec_helper'

describe "Shipments" do
  before(:each) do
    single_store_setup
    sleep(4)
    login_employee("31202053295")
  end
  def click_on(id)
    find(id).click
    sleep(1)
  end
  it "should allow you to create a shipper", :js => true, :driver => :selenium do
    visit "/vendors"
    find("#vendor_#{@vendor.id}").click
    sleep(1)
    find("#edit_shippers").click
    sleep(1)
    find("#new_shipper").click
    sleep(1)
    fill_in("shipper[name]",:with => "This is a shipper")
    find("#submit").click
    sleep(1)
    Shipper.last.name.should == "This is a shipper"
  end
  it "should allow you to creat shipment types", :js => true, :driver => :selenium do
    visit "/vendors"
    click_on("#vendor_#{@vendor.id}")
    click_on("#edit_shippers")
    click_on("#edit_shipment_types")
    click_on("#new_shipment_type")
    fill_in("shipment_type[name]", :with => "This is a test shipment type")
    click_on("#submit")
    page.should have_content("created successfully")
    ShipmentType.last.name.should == "This is a test shipment type"
    visit("/shipments")
    click_on("#new_shipment")
    click_on("#select_widget_button_for_shipment_shipment_type_id")
    find(".select-widget-display-shipment_shipment_type_id").should have_content("This is a test shipment type")
    
  end
  it "should allow you to create a shipment", :js => true, :driver => :selenium do
    # first create a shipper
    visit "/vendors"
    find("#vendor_#{@vendor.id}").click
    sleep(1)
    find("#edit_shippers").click
    sleep(1)
    find("#new_shipper").click
    sleep(1)
    fill_in("shipper[name]",:with => "This is a shipper")
    find("#submit").click
    # then create a shipment type
    visit "/shipment_types?vendor_id=#{@vendor.id}" 
    click_on("#new_shipment_type")
    fill_in("shipment_type[name]", :with => "This is a test shipment type")
    click_on("#submit")
    visit("/shipments")
    click_on("#new_shipment")
    click_on("#select_widget_button_for_shipment_shipment_type_id")
    click_on("#active_select_#{ShipmentType.last.id}")
    click_on("#select_widget_button_for_shipment_the_shipper")
    click_on("#active_select_Shipper-#{Shipper.last.id}")
    fill_in("shipment[name]",:with => "Test Shipment")
    click_on("#new_shipment_item")
    fill_in("shipment[set_items][0][sku]", :with => @item.sku)
    fill_in("shipment[set_items][0][quantity]", :with => 1)
    page.execute_script(@enter_event.gsub("INPUT",".attribute-input-sku"));
    sleep(1)
    click_on("#submit")
    begin
      page.driver.browser.switch_to.alert.accept
    rescue
      puts "weird"
    end
    qty = @item.quantity
    sleep(2)
    page.should have_content("Test Shipment")
    page.should have_content(@item.name)
    Shipment.count.should == 1
    Shipment.last.name.should == "Test Shipment"
    Shipment.last.shipment_items.count.should == 1
    Shipment.last.shipment_items.first.sku.should == @item.sku
    Shipment.last.shipment_items.first.quantity.should == 1
    click_on("#button-move-all-shipment-items")
    sleep(1)
    page.should have_content("Items moved")
    sleep(1)
    @item.reload
    sleep(1)
    Item.find(@item.id).quantity.should == qty + 1
  end
  it "should allow you to create a negative shipment", :js => true, :driver => :selenium do
    # first create a shipper
    visit "/vendors"
    find("#vendor_#{@vendor.id}").click
    sleep(1)
    find("#edit_shippers").click
    sleep(1)
    find("#new_shipper").click
    sleep(1)
    fill_in("shipper[name]",:with => "This is a shipper")
    find("#submit").click
    # then create a shipment type
    visit "/shipment_types?vendor_id=#{@vendor.id}" 
    click_on("#new_shipment_type")
    fill_in("shipment_type[name]", :with => "This is a test shipment type")
    click_on("#submit")
    visit("/shipments")
    click_on("#new_shipment")
    click_on("#select_widget_button_for_shipment_shipment_type_id")
    click_on("#active_select_#{ShipmentType.last.id}")
    click_on("#select_widget_button_for_shipment_the_shipper")
    click_on("#active_select_Vendor-#{@vendor.id}")
    sleep(1)
    click_on("#select_widget_button_for_shipment_the_receiver")
    click_on("#active_select_Shipper-#{Shipper.last.id}")
    fill_in("shipment[name]",:with => "Test Shipment")
    click_on("#new_shipment_item")
    fill_in("shipment[set_items][0][sku]", :with => @item.sku)
    fill_in("shipment[set_items][0][quantity]", :with => 1)
    page.execute_script(@enter_event.gsub("INPUT",".attribute-input-sku"));
    sleep(1)
    click_on("#submit")
    begin
      page.driver.browser.switch_to.alert.accept
    rescue
      puts "weird"
    end
    qty = @item.quantity
    sleep(2)
    page.should have_content("Test Shipment")
    page.should have_content(@item.name)
    Shipment.count.should == 1
    Shipment.last.name.should == "Test Shipment"
    Shipment.last.shipment_items.count.should == 1
    Shipment.last.shipment_items.first.sku.should == @item.sku
    Shipment.last.shipment_items.first.quantity.should == 1
    click_on("#button-move-all-shipment-items")
    sleep(1)
    page.should have_content("Items moved")
    sleep(1)
    @item.reload
    sleep(1)
    Item.find(@item.id).quantity.should == qty - 1
  end
  it "should allow you to create a new item during shipment creation", :js => true, :driver => :selenium do
    # first create a shipper
    visit "/vendors"
    find("#vendor_#{@vendor.id}").click
    sleep(1)
    find("#edit_shippers").click
    sleep(1)
    find("#new_shipper").click
    sleep(1)
    fill_in("shipper[name]",:with => "This is a shipper")
    find("#submit").click
    # then create a shipment type
    visit "/shipment_types?vendor_id=#{@vendor.id}" 
    click_on("#new_shipment_type")
    fill_in("shipment_type[name]", :with => "This is a test shipment type")
    click_on("#submit")
    visit("/shipments")
    click_on("#new_shipment")
    click_on("#select_widget_button_for_shipment_shipment_type_id")
    click_on("#active_select_#{ShipmentType.last.id}")
    click_on("#select_widget_button_for_shipment_the_receiver")
    click_on("#active_select_Vendor-#{@vendor.id}")
    sleep(1)
    click_on("#select_widget_button_for_shipment_the_shipper")
    click_on("#active_select_Shipper-#{Shipper.last.id}")
    fill_in("shipment[name]",:with => "Test Shipment")
    click_on("#new_shipment_item")
    new_sku = "12345"
    fill_in("shipment[set_items][0][sku]", :with => new_sku)
    page.execute_script(@enter_event.gsub("INPUT",".attribute-input-sku"))
    sleep(1)
    #now we fill in the data
    find(".create-name-input").set("Test Item Creation")
    find(".create-base_price-input").set(39.95)
    click_on("div.shipment-create-item * #confirm")
    sleep(1)
    fill_in("shipment[set_items][0][quantity]", :with => 3)
    click_on("#submit")
    begin
      page.driver.browser.switch_to.alert.accept
    rescue
      puts "weird"
    end
    sleep(2)
    page.should have_content("Test Shipment")
    page.should have_content("Test Item Creation")
    Shipment.count.should == 1
    Shipment.last.name.should == "Test Shipment"
    Shipment.last.shipment_items.count.should == 1
    Shipment.last.shipment_items.first.sku.should == new_sku
    Shipment.last.shipment_items.first.quantity.should == 3
    click_on("#button-move-all-shipment-items")
    sleep(1)
    page.should have_content("Items moved")
    sleep(1)
    Item.find_by_sku(new_sku).quantity.should == 3
  end
end
