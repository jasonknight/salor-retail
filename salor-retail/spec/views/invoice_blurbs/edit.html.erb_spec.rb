require 'spec_helper'

describe "invoice_blurbs/edit" do
  before(:each) do
    @invoice_blurb = assign(:invoice_blurb, stub_model(InvoiceBlurb,
      :lang => "MyString",
      :body => "MyText",
      :is_header => false
    ))
  end

  it "renders the edit invoice_blurb form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => invoice_blurbs_path(@invoice_blurb), :method => "post" do
      assert_select "input#invoice_blurb_lang", :name => "invoice_blurb[lang]"
      assert_select "textarea#invoice_blurb_body", :name => "invoice_blurb[body]"
      assert_select "input#invoice_blurb_is_header", :name => "invoice_blurb[is_header]"
    end
  end
end
