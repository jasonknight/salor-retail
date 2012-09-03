require 'spec_helper'
describe OrderItem do
  context "when being created" do
      it "accepts a normal item" do
        single_store_setup
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @order_item = OrderItem.new
        @order_item.should be_valid
        @order_item.set_item(@item)
        @order_item.price.should == @item.price.first
      end # accepts an item
      it "decrements item quantities when set_sold" do
        single_store_setup
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @item.category.should be
        qty = @item.quantity
        @order_item = OrderItem.new
        @order_item.set_item(@item)
        @order_item.set_sold
        @order_item.item.quantity.should == qty - @order_item.quantity
      end # decrements item quantities when set_sold
      it "accepts a parts item" do
        single_store_setup
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @order_item = OrderItem.new
        @parts_item = Factory :item,:sku => "PART", :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @parts_item.part_quantity = 10
        @item.parts << @parts_item
        @item.calculate_part_price = true
        @order_item.price.should == 0
        @order_item.set_item(@item)
        @order_item.price.should == @parts_item.price.first * @parts_item.part_quantity
        @order_item.item.parts.first.quantity.should == 100
        @order_item.set_sold
        @order_item.item.parts.first.quantity.should == 90
      end # accepts a parts item
      it "should have a list of discounts" do
       single_store_setup
       @discount = Factory :discount, :vendor => @vendor, :category => @category
       @discount.save
       Discount.count.should == 1
       puts Discount.first.inspect
       OrderItem.reload_discounts
       @order_item = OrderItem.new
       OrderItem.get_discounts.length.should == 1
      end 
      it "should should consider discounts that apply to the category of an item" do
        single_store_setup
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @discount = Factory :discount, :vendor => @vendor, :category => @category, :start_date => Time.now - 1.day, :end_date => Time.now + 1.day,:amount_type => 'percent'
        @discount.save
        Discount.count.should_not == 0
        puts Discount.first.inspect
        @discount.update_attribute :applies_to, 'Category'
        @discount.update_attribute :category_id, @item.category_id
        OrderItem.reload_discounts
        @order_item = OrderItem.new
        @order_item.set_item(@item)
        @order_item.discounts.count.should == 1
        @order_item.calculate_total(0)
        @order_item.total.should_not == @item.base_price
        @order_item.total.should be_within(0.05).of(@item.base_price / 2)
      end
  end # when being created
end
