require 'spec_helper'

describe "Items" do
  before(:each) do
    single_store_setup
    @item = Factory :item, :vendor => @vendor, :tax_profile => @tax_profile, :category => @category
  end
   describe "GET /employess/login" do
      it "should render printr label" do
          @item.should be_valid
         visit "/items/render_label?id=#{@item.id}&type=label"
         page.should have_content(@item.name)
      end
      it "should render printr sticker label" do
        visit "/items/render_label?id=#{@item.id}&type=sticker"
        page.should have_content(@item.sku)
      end
   end
end
