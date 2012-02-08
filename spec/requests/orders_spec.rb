require 'spec_helper'

describe "Orders" do
  before(:each) do
  end
  describe "GET /orders" do
    it "renders printr templates upon request" do
      single_store_setup
      @item.should be_valid
      @order.add_item(@item)
      @order.order_items.length.should == 1
      @order.update_self_and_save
      visit "/orders/render_order_receipt?order_id=#{@order.id}"
      page.should have_content(@item.name)
    end
    it "renders nothing when there is no order" do
      single_store_setup
      @order.destroy
      visit "/orders/render_order_receipt?order_id=#{@order.id}"
      page.should_not have_content(@item.name)
      "<a href='latal?'>hello</a>".gsub(/\<[^\>]+\>/,'').should == "hello"
      page.body.gsub(/\<[^\>]+\>/,'').strip.should be_empty
    end
    it "does not show the menu bar for cashiers", :js => true, :driver => :webkit do
      single_store_setup
      login_employee('31202003285')
      visit "/cash_registers?vendor_id=#{@vendor.id}"
      page.should have_content('Cash Register')
      visit "/orders/new?cash_register_id=#{@cash_register.id}"
      page.should have_no_selector('.header')
    end
    it "shows the menu bar for managers", :js => true, :driver => :webkit do
      single_store_setup
      login_employee('31202053295')
      visit "/cash_registers?vendor_id=#{@vendor.id}"
      visit "/orders/new?cash_register_id=#{@cash_register.id}"
      page.should have_selector('.header')
    end
    it "allows a cashier to enter an item", {:js => true, :driver => :webkit} do
      single_store_setup
      login_employee('31202003285')
      visit "/cash_registers?vendor_id=#{@vendor.id}"
      visit "/orders/new?cash_register_id=#{@cash_register.id}"
      fill_in "keyboard_input", :with => @item.sku
      page.execute_script(@enter_event.gsub("INPUT","#keyboard_input"));
      page.should have_content(@item.name)
      page.should have_content(@item.sku)
      fill_in "keyboard_input", :with => @item.sku
      page.execute_script(@enter_event.gsub("INPUT","#keyboard_input"));
      sleep(1)
      #save_and_open_page
      page.find(".pos-order-total").should have_content(SalorBase.number_to_currency(@item.base_price * 2))
      fill_in "keyboard_input", :with => @item2.sku
      page.execute_script(@enter_event.gsub("INPUT","#keyboard_input"));
      page.find(".pos-order-total").should have_content(SalorBase.number_to_currency((@item.base_price * 2) + @item2.base_price))
    end
    it "stores calculated change on the order" do
      single_store_setup
      login_employee('31202053295')
      visit "/cash_registers?vendor_id=#{@vendor.id}"
      visit "/orders/new?cash_register_id=#{@cash_register.id}"
      change = "46,68"
      url = "/vendors/edit_field_on_child?order_id=#{@order.id}&klass=Order&field=front_end_change&value=#{change}"
      visit url
      Order.find(@order.id).front_end_change.should == 46.68
      change = "$346.68"
      url = "/vendors/edit_field_on_child?order_id=#{@order.id}&klass=Order&field=front_end_change&value=#{change}"
      visit url
      Order.find(@order.id).front_end_change.should == 346.68
      change = "abc"
      url = "/vendors/edit_field_on_child?order_id=#{@order.id}&klass=Order&field=front_end_change&value=#{change}"
      visit url
      Order.find(@order.id).front_end_change.should == 0
    end
  end
end
