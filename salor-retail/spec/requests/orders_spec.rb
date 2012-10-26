require 'spec_helper'

describe "Orders" do
  before(:each) do
    single_store_setup
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category   
  end
  def add_item_of(amount)
    fill_in "keyboard_input", :with => amount
    sleep(1)
    page.execute_script(@enter_event.gsub("INPUT","#keyboard_input"));
    sleep(1)
  end
  def complete!
    find("#confirm_complete_order_button").click
    sleep(2)
    find("#cancel_complete_order_button").click
    sleep(2)
  end
  def change
    find("#complete_order_change")
  end
  def last_order
    sleep(1)
    Order.where("id < #{Order.last.id}").order("id desc").first
  end
  def order
    sleep(1)
    Order.last
  end
  def check_receipt(total=nil,change=nil,cash=nil,credit=nil,other=nil)
    sleep(1)
    written_file = File.open(@cash_register.thermal_printer,'r') {|f| f.read}
    [written_file,last_thermal_receipt].each do |receipt|
      receipt.match(/TOTAL.+#{total.to_s}/).should_not be_nil if total
      receipt.match(/Change money.+#{change.to_s}/).should_not be_nil if change
      receipt.match(/ByCard.+#{credit.to_s}/).should_not be_nil if credit
      receipt.match(/InCash.+#{cash.to_s}/).should_not be_nil if cash
      receipt.match(/OtherCredit.+#{other.to_s}/).should_not be_nil if other
    end
  end
  it "conforms to the steps in the testing manual", :js => true, :driver => :selenium do
    sleep(5)
    if User.count == 0 then
      single_store_setup
    end
    login_employee('31202003285') # Log in as a cashier
    visit "/cash_registers?vendor_id=#{@vendor.id}"
    visit "/orders/new?cash_register_id=#{@cash_register.id}"
    # Cash Drop of 100

    find(".cash-drop-header").click
    fill_in "transaction[amount]", :with => ""
    fill_in "transaction[amount]", :with => "100"
    find("#confirm_cash_drop").click
    visit "/orders/new?cash_register_id=#{@cash_register.id}"
    begin
      page.driver.browser.switch_to.alert.accept
    rescue
      puts "weird"
    end
    find("#header_drawer_amount").should have_content("100")
    dt = DrawerTransaction.first
    dt.amount.should == 100
    dt.drop.should == true
    
    #add item of 10.00
    #visit "/orders/new?cash_register_id=#{@cash_register.id}"
    add_item_of("10.00")
    find("#print_receipt_button").click
    sleep(1)
    change.should have_content("0.00")
    complete!
    check_receipt(10.00,0.00)
    find("#header_drawer_amount").should have_content("110")
    
    #add item of 5
    add_item_of("5.00")
    find("#print_receipt_button").click
    fill_in "payment_amount_0", :with => "10.50"
    sleep(1)
    
    change.should have_content("5.50")
    sleep(2)
    order.front_end_change.should == 5.5
    complete!
    check_receipt(5.00,5.50,10.50)
    last_order.front_end_change.should == 5.5
    
    find("#header_drawer_amount").should have_content("115")
    
    # add item of 20.00
    add_item_of("20.00")
    find("#print_receipt_button").click
    fill_in "payment_amount_0", :with => "20"
    find("#add_payment_method_button").click
    sleep(2)
    fill_in "payment_amount_1", :with => "10"
    change.should have_content("10.00")
    order.front_end_change.should == 10.00
    complete!
    find("#header_drawer_amount").should have_content("125")
    check_receipt(20.00,10.00,20.00,10.00)
    
    # add item of 40
    add_item_of("40.00")
    find("#print_receipt_button").click
    find("#complete_piece_50").click
    sleep(1)
    find("#add_payment_method_button").click
    sleep(1)
    find("#select_widget_button_for_payment_type_1").click
    find("#active_select_OtherCredit").click
    sleep(1)
    fill_in "payment_amount_1", :with => "5"
    change.should have_content("15.00")
    order.front_end_change.should == 15.00
    complete!
    last_order.front_end_change.should == 15.00
    last_order.payment_methods.count.should == 2
    
    check_receipt(40.00,15.00,50.00,nil,5.00)
    
    find("#header_drawer_amount").should have_content("160")
    
    # test buyback item
    
    add_item_of("10.00")
    id = order.order_items.first.id
    find("#order-item-#{id}_name_inp").click
    sleep(1)
    find("#item_menu_buyback").click
    sleep(2)
    find("#order-item-#{id}_price_inp").click
    find(".inplaceeditinput").set(1)
    sleep(1)
    find(:css,"input[name=key_accept]").click
    find("#print_receipt_button").click
    sleep(1)
    complete!
    find("#header_drawer_amount").should have_content("159")
    # test buy order 
    
    add_item_of("10.00")
    id1 = order.order_items.first.id
  
    add_item_of("20.00")
    id2 = order.order_items.last.id
    
    find("#buy_order_button").click
    sleep(1)
    
    find("#order-item-#{id1}_price_inp").click
    find(".inplaceeditinput").set(1)
    sleep(1)
    find(:css,"input[name=key_accept]").click
    
    find("#order-item-#{id2}_price_inp").click
    find(".inplaceeditinput").set(2)
    sleep(1)
    find(:css,"input[name=key_accept]").click
    
    find("#print_receipt_button").click
    sleep(2)
    complete!
    find("#header_drawer_amount").should have_content("156")
    
    # end day
    
    find("#end_of_day_button").click
    sleep(3)
    find("#eod_piece_5").set(5)
    find("#eod_piece_10").set(5)
    find("#eod_piece_25").set(5)
    find("#eod_piece_50").set(6)
    find("#eod_piece_100").set(6)
    find("#eod_piece_500").set(5)
    find("#eod_piece_1000").set(5)
    find("#eod_piece_2000").set(1)
    find("#eod_piece_5000").set(1)
    
    find("#eod_piece_5000").click
    
    find("#eod-calculator-total").should have_content("156.00")
    #cash payout of 156
    
    find(".cash-drop-header").click
    fill_in "transaction[amount]", :with => ""
    fill_in "transaction[amount]", :with => "156"
    find("#confirm_cash_payout").click
    
    sleep(3)
    
    dt = DrawerTransaction.last
    dt.amount.should == 156
    dt.drop.should_not == true
    dt.payout.should == true
    
    find("#go_to_report_day").click
    
    sleep(3)
    
    find("#select_widget_button_for_employee_select").click
    sleep(1)
    find("#active_select_" + @cashier.id.to_s).click
    find("#display_report_day").click
    sleep(3)
    find("#pos_InCash_sum").should have_content("60")
    find("#pos_ByCard_sum").should have_content("10")
    find("#pos_OtherCredit_sum").should have_content("5")
    find("#pos_sum_gross").should have_content("75")
    find("#neg_InCash_sum").should have_content("4")
    
    find("#end_of_day_button").click
    sleep(1)
    find("#confirm_print_end_of_day_report").click
    sleep(2)
    find("#confirm_end_of_day").click
    
    #check the end of day print
    last_thermal_receipt.match(/In Cash.+60.00/).should_not be_nil
    last_thermal_receipt.match(/Card.+10.00/).should_not be_nil
    last_thermal_receipt.match(/Other.+5.00/).should_not be_nil
    last_thermal_receipt.match(/TOTAL.+75.00/).should_not be_nil
    last_thermal_receipt.match(/TOTAL.+\-4.00/).should_not be_nil
    last_thermal_receipt.match(/TOTAL.+71.00/).should_not be_nil
    last_thermal_receipt.match(/Tax Profile.+62.50.+75.00/).should_not be_nil
    
  end
  it "renders printr templates upon request", :js => true, :driver => :selenium do
    @item.should be_valid
    @order.add_item(@item)
    @order.order_items.length.should == 1
    @order.update_self_and_save
    @cash_register.update_attribute(:salor_printer,true)
    visit "/orders/print_receipt?order_id=#{@order.id}&user_id=#{@manager.id}&cash_register_id=#{@cash_register.id}"
    page.should have_content(@item.name)
  end
  it "renders nothing when there is no order", :js => true, :driver => :selenium do
    @order.destroy
    @cash_register.update_attribute(:salor_printer,true)
    visit "/orders/print_receipt?order_id=#{@order.id}&user_id=#{@manager.id}&cash_register_id=#{@cash_register.id}"
    page.should_not have_content(@item.name)
    page.body.gsub(/\<[^\>]+\>/,'').strip.should be_empty
  end
  it "shows the menu bar for managers", :js => true, :driver => :selenium do
    login_employee('31202053295')
    visit "/cash_registers?vendor_id=#{@vendor.id}"
    visit "/orders/new?cash_register_id=#{@cash_register.id}"
    page.should have_selector('.header')
  end
  it "stores calculated change on the order", :js => true, :driver => :selenium do
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
