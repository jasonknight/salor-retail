require 'spec_helper'
describe Shipment do
  before(:each) do
    @user = Factory :user
    @vendor = Factory :vendor, :user => @user
    @cash_register = Factory :cash_register, :vendor => @vendor
    @tax_profile = Factory :tax_profile, :user => @user
    @category = Factory :category, :vendor => @vendor
    GlobalData.salor_user = @user
    GlobalData.vendor = @vendor
    GlobalData.vendor_id = @vendor.id
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @shipper = Factory(:shipper, :user => @user)
    @shipment = Factory(:shipment,
                        :vendor => @vendor,
                        :user => @user)
    @stock_location = Factory(:stock_location,
                              :vendor => @vendor)
    @shipment_item = Factory(:shipment_item,
                             :shipment => @shipment,
                             :sku => @item.sku)
  end
  context "basic shipment functionality" do
    it "should allow you to create a shipment with shipment items" do
      @shipment.should be_valid
      @shipment.shipment_items.length.should == 1
    end # should allow you to create a shipment with shipment items
  end # basic shipment functionality
  context "when the vendor is the receiver" do
    it "should assign shipper and receiver" do
      @shipment.the_receiver = "Vendor:#{@vendor.id}"
      @shipment.the_shipper = "Shipper:#{@shipper.id}"
      @shipment.should be_valid
      @shipment.shipper.should == @shipper
      @shipment.receiver.should == @vendor
    end # should assign shipper and receiver
    it "should move all items over" do
      @shipment.the_receiver = "Vendor:#{@vendor.id}"
      @shipment.the_shipper = "Shipper:#{@shipper.id}"
      qty = @item.quantity
      @shipment.move_all_to_items
      @item.reload.quantity.should == qty + @shipment_item.quantity
    end # should move all items over
  end # when the vendor is the receiver
  context "when the vendor is the shipper" do
    it "should decrement the item quantities" do
      @shipment.the_receiver = "Shipper:#{@shipper.id}"
      @shipment.the_shipper = "Vendor:#{@vendor.id}"
      @shipment.reload.shipper.should == @vendor
      qty = @item.quantity
      @shipment.move_all_to_items
      @item.reload.quantity.should == qty - @shipment_item.quantity
    end # should decrement the item quantities
  end # when the vendor is the shipper
end
