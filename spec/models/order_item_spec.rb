require 'spec_helper'
describe OrderItem do
  before(:each) do
    @user = Factory :user
    @vendor = Factory :vendor, :user => @user
    @tax_profile = Factory :tax_profile, :user => @user
    @category = Factory :category, :vendor => @vendor
  end
  context "when being created" do
      it "accepts a normal item" do
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @order_item = OrderItem.new
        @order_item.should be_valid
        @order_item.set_item(@item)
        @order_item.price.should == @item.price.first
      end # accepts an item
      it "decrements item quantities when set_sold" do
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @item.category.should be
        qty = @item.quantity
        @order_item = OrderItem.new
        @order_item.set_item(@item)
        @order_item.set_sold
        @order_item.item.quantity.should == qty - @order_item.quantity
      end # decrements item quantities when set_sold
      it "accepts a parts item" do
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
       @discount = Factory :discount, :vendor => @vendor, :category => @category
       @discount.save
       OrderItem.reload_discounts
       @order_item = OrderItem.new
       OrderItem.get_discounts.length.should == 1
      end 
      it "should should consider discounts that apply to the categor of an item" do
        @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
        @discount = Factory :discount, :vendor => @vendor, :category => @category
        @discount.update_attribute :applies_to, 'Category'
        @discount.update_attribute :category_id, @item.category_id
        OrderItem.reload_discounts
        @order_item = OrderItem.new
        @order_item.set_item(@item)
        @order_item.price.should_not == @item.base_price
        @order_item.price.should be_within(0.05).of(@item.base_price / 2)
      end
  end # when being created
end
