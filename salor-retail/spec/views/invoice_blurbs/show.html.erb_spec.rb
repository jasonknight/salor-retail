require 'spec_helper'

describe "invoice_blurbs/show" do
  before(:each) do
    @invoice_blurb = assign(:invoice_blurb, stub_model(InvoiceBlurb,
      :lang => "Lang",
      :body => "MyText",
      :is_header => false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Lang/)
    rendered.should match(/MyText/)
    rendered.should match(/false/)
  end
end
