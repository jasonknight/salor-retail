require "spec_helper"

describe InvoiceBlurbsController do
  describe "routing" do

    it "routes to #index" do
      get("/invoice_blurbs").should route_to("invoice_blurbs#index")
    end

    it "routes to #new" do
      get("/invoice_blurbs/new").should route_to("invoice_blurbs#new")
    end

    it "routes to #show" do
      get("/invoice_blurbs/1").should route_to("invoice_blurbs#show", :id => "1")
    end

    it "routes to #edit" do
      get("/invoice_blurbs/1/edit").should route_to("invoice_blurbs#edit", :id => "1")
    end

    it "routes to #create" do
      post("/invoice_blurbs").should route_to("invoice_blurbs#create")
    end

    it "routes to #update" do
      put("/invoice_blurbs/1").should route_to("invoice_blurbs#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/invoice_blurbs/1").should route_to("invoice_blurbs#destroy", :id => "1")
    end

  end
end
