require 'spec_helper'

describe "invoice_blurbs/index" do
  before(:each) do
    assign(:invoice_blurbs, [
      stub_model(InvoiceBlurb,
        :lang => "Lang",
        :body => "MyText",
        :is_header => false
      ),
      stub_model(InvoiceBlurb,
        :lang => "Lang",
        :body => "MyText",
        :is_header => false
      )
    ])
  end

  it "renders a list of invoice_blurbs" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Lang".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
