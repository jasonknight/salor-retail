require 'spec_helper'

describe "Report Day" do
  before(:each) do
    single_store_setup
    login_employee "31202053295"
    @order.add_item @item
    @order.set_model_owner @manager
    @order.update_self_and_save
    @order.complete
    @single_order_item = @order.order_items.first
    visit "/orders/report_day?vendor_id=#{ @vendor.id }&employee_id=#{ @manager.id }"
  end
  describe "category statistics"
    it "calculates positive gross correctly" do
      #save_and_open_page
      fieldname = "category_sums_positive_gro_#{ @single_order_item.category.id }"
      find_field(fieldname).value.should == @single_order_item.price.to_s
    end
    #
    it "calculates positive net correctly" do
      #save_and_open_page
      fieldname = "category_sums_positive_net#{ @single_order_item.category.id }"
      item = @order.order_items.first
      find_field(fieldname).value.should == (@single_order_item.price / (1 + @tax_profile.value / 100 )).to_s
    end
    #
    it "calculates negative gross correctly" do
      #save_and_open_page
      fieldname = "category_sums_positive_net#{ @single_order_item.category.id }"
      item = @order.order_items.first
      find_field(fieldname).value.should == (@single_order_item.price / (1 + @tax_profile.value / 100 )).to_s
    end
  end
end
