require 'spec_helper'
require 'pp'
describe Order do
  before(:each) do
    single_store_setup
    @order = Factory :order, :user => @user, :vendor => @vendor, :cash_register => @cash_register
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    
  end
  def create_taxable_order
    @vendor = Factory :vendor, :user => @user
    @vendor.salor_configuration.calculate_tax = true
    $Conf = @vendor.salor_configuration
    @order = Factory :order, :user => @user, :vendor => @vendor, :cash_register => @cash_register
  end
  def create_pc_items
    @carton = Factory :item, :quantity => 1,:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @carton.update_attribute(:packaging_unit,1)
    @pack = Factory :item, :quantity => 10,:sku => "PACK",:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @pack.update_attribute(:packaging_unit,10)
    @piece = Factory :item, :quantity => 20,:sku => "PIECE",:vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @piece.update_attribute(:packaging_unit,20)
    @piece.parent_sku = @pack.sku
    @pack.parent_sku = @carton.sku
  end
  def create_gift_cards
    gc_item_type = Factory(:item_type, :behavior => 'gift_card')
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @gift_card = Factory(:item, 
                    :sku => "GCARD",
                    :base_price => 10,
                    :vendor => @vendor, 
                    :tax_profile => @tax_profile, 
                    :category => @category,
                    :item_type => gc_item_type)
  end
  def create_coupons
    coupon_item_type = Factory(:item_type, :behavior => 'coupon')
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
    @poff = Factory(:item, 
                    :sku => "CTESTpoff",
                    :base_price => 50,
                    :vendor => @vendor, 
                    :tax_profile => @tax_profile, 
                    :category => @category,
                    :item_type => coupon_item_type,
                    :coupon_type => 1,
                    :coupon_applies => @item.sku)
    @b1g1 = Factory(:item, 
                    :sku => "CTESTb1g1",
                    :base_price => 50,
                    :vendor => @vendor, 
                    :tax_profile => @tax_profile, 
                    :category => @category,
                    :item_type => coupon_item_type,
                    :coupon_type => 3,
                    :coupon_applies => @item.sku)
    @fixed = Factory(:item, 
                    :sku => "CTESTFixed",
                    :base_price => 0.95,
                    :vendor => @vendor, 
                    :tax_profile => @tax_profile, 
                    :category => @category,
                    :item_type => coupon_item_type,
                    :coupon_type => 2,
                    :coupon_applies => @item.sku)
    
  end
  context "when creating an order" do
    it "should be valid" do
      @order.should be_valid
    end # should be valid
    it "should accept internationalized price input" do
      @order.total = "10,95"
      @order.total.should == 10.95
      @order.rebate = "1,2"
      @order.rebate.should == 1.2
      @order.subtotal = "3,95"
      @order.subtotal.should == 3.95
      @order.tax = "11,27"
      @order.tax.should == 11.27
    end # should accept internationalized price input
    it "should return it's owner" do
      @order.get_owner.should == @user
    end # should return it's owner
    it "should add an item" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @item.should be_valid
      @order.add_item(@item)
      @order.order_items.length.should == 1
    end # should add an item
    it "should update its totals" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @item.should be_valid
      @order.add_item(@item)
      @order.update_self_and_save
      @order.gross.should == @item.base_price
    end # should update its totals
    it "should increment quantity when passed a duplicate item" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @item.should be_valid
      @order.add_item(@item)
      @order.add_item(@item)
      @order.order_items.length.should == 1
    end # should increment quantity when passed a duplicate item
    it "should not recalculate the total after paid" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @order.add_item(@item)
      @order.update_self_and_save
      @order.gross.should == @item.base_price
      @order.complete
      @order.order_items.first.update_attribute(:price, 1)
      @order.reload
      @order.update_self_and_save
      @order.gross.should == @item.base_price
    end # should not recalculate the total after paid
    it "should not allow you to remove and item once paid" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @order.add_item(@item)
      @order.update_self_and_save
      @order.gross.should == @item.base_price
      @order.complete
      @order.remove_order_item(@order.order_items.first)
      @order.order_items.reload.first.should be
    end # should not allow you to remove and item once paid
    it "should allow you to refund a single item" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @order.add_item(@item)
      @order.update_self_and_save
      @order.complete
      DrawerTransaction.last.amount.should == @order.get_drawer_add
      DrawerTransaction.last.tag.should == 'CompleteOrder'
      @order.order_items.first.toggle_refund(true,'InCash')
      @order.gross.should == 0.0
      DrawerTransaction.last.amount.should == @order.order_items.first.total
      DrawerTransaction.last.order_id.should == @order.id
      DrawerTransaction.last.order_item_id.should == @order.order_items.first.id
      DrawerTransaction.last.is_refund.should == true
    end
    it "should allow you to refund an entire order" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      @order.add_item(@item)
      @order.update_self_and_save
      @order.complete
      DrawerTransaction.last.amount.should == @order.get_drawer_add
      DrawerTransaction.last.tag.should == 'CompleteOrder'
      @order.toggle_refund(true,'InCash')
      DrawerTransaction.last.amount.should == @order.subtotal
      DrawerTransaction.last.order_id.should == @order.id
      DrawerTransaction.last.order_item_id.should_not == @order.order_items.first.id
      DrawerTransaction.last.is_refund.should == true
    end
  end # when creating an order
  context "when using coupons" do
    it "should accept coupons" do
      @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
      create_coupons
      @order.add_item(@poff)
      @order.order_items.length.should == 1
      @order.update_self_and_save
      @order.gross.should == 0
      @order.add_item(@item)
      @order.update_self_and_save
      @order.gross.should_not == @item.base_price
    end # should accept coupons
    it "should only allow 1 coupon per item discount." do
      create_coupons
      @order.add_item(@poff)
      @order.add_item(@item)
      @order.update_self_and_save
      ttl = @order.gross
      @order.add_item(@item)
      @order.update_self_and_save
      @order.gross.should == (ttl + @item.base_price)
    end # should only allow 1 coupon per item discount.
    it "should allow multiple coupons of the same type" do
      create_coupons
      @order.add_item(@poff)
      @order.add_item(@item)
      @order.add_item(@item)
      @order.add_item(@poff)
      @order.update_self_and_save
      @order.gross.should_not == (@item.base_price * 2)
    end # should allow multiple coupons of the same type
    it "should allow b1g1 coupons" do
      create_coupons
      @order.add_item(@b1g1)
      @order.add_item(@item)
      @order.update_self_and_save
      @order.gross.should == @item.base_price
      @order.add_item(@item)
      @order.gross.should == @item.base_price
    end # should allow b1g1 coupons
    it "should handle fixed amount coupons" do
      create_coupons
      @order.add_item(@item)
      @order.add_item(@fixed)
      @order.update_self_and_save
      @order.gross.should == (@item.base_price - @fixed.base_price)
    end # should handle fixed amount coupons
  end # when using coupons
  context "when using gift cards" do
    it "should sell a gift card normally" do
      create_gift_cards
      @order.add_item(@gift_card)
      @order.update_self_and_save
      @order.gross.should == 10
    end # should sell a gift card normally
    it "should activate gift cards on the order at the end" do
      create_gift_cards
      @order.add_item(@gift_card)
      @order.update_self_and_save
      @order.complete
      @order.paid.should == 1
      @order.order_items.reload.first.item.activated.should == true
    end # should activate gift cards on the order at the end
    it "should discount orders when using an activated giftcard"  do
      create_gift_cards
      @order.add_item(@gift_card)
      @order.update_self_and_save
      @order.complete
      @order.paid.should == 1
      @order2 = Factory :order, :user => @user, :vendor => @vendor, :cash_register => @cash_register
      @gift_card.reload
      @gift_card.activated.should == true
      @order2.gross.should == 0
      @order2.add_item(@item)
      @order2.update_self_and_save
      
      @order2.add_item(@gift_card)
      @order2.update_self_and_save
      
      @order2.gross.should == 0
      @order2.order_items.last.update_attribute(:price,5)
      @order2.update_self_and_save
      @order2.gross.should == 0.95
    end # should discount orders when using an activated giftcard
  end # when using gift cards
  context "when vendor.calculate_tax is set to true" do
    it "should return the total + tax" do
      create_taxable_order
      @order.add_item(@item)
      @order.update_self_and_save
      @order.subtotal.should be_within(0.005).of(@item.base_price)
      @order.gross.should be_within(0.005).of(@order.order_items.first.tax + @order.subtotal)
      @order.subtotal.should_not == @order.gross
    end # should return the total + tax
  end # when vendor.calculate_tax is set to true
  context "when working with parent/child items" do
    it "should update parent quantity when selling more than packaging unit" do
      create_pc_items
      pqty = @piece.quantity
      pkqty = @pack.quantity
      @piece.parent.should be
      @piece.reload.parent.reload.should be
      @order.add_item(@piece)
      @order.order_items.first.update_attribute :quantity, 21
      @order.update_self_and_save
      @order.complete
      @order.reload.paid.should == 1
      @piece.reload.quantity.should == @pack.packaging_unit - 1
      @pack.reload.quantity.should == pkqty - 1
    end # should update parent quantity when selling more than packaging unti
  end # when working with parent/child items
end
