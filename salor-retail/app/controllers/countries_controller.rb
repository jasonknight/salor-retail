class CountriesController < ApplicationController
  

  def index
    @countries = @current_vendor.countries.visible.page(params[:page]).per(@current_vendor.pagination)
  end
  
  def new
    @country = Country.new
  end
  
  def show
    @country = @current_vendor.countries.visible.find_by_id(params[:id])
    redirect_to edit_country_path(@country)
  end
  
  def create
    @country = Country.new(params[:country])
    @country.vendor = @current_vendor
    @country.company = @current_company
    if @country.save
      redirect_to countries_path
    else
      render :new
    end
  end
  
  def update
    @country = @current_vendor.countries.visible.find_by_id(params[:id])
    if @country.update_attributes(params[:country])
      redirect_to countries_path
    else
      render :new
    end
  end
  
  def edit
    @country = @current_vendor.countries.visible.find_by_id(params[:id])
    render :new
  end
  
  def destroy
    @country = @current_vendor.countries.visible.find_by_id(params[:id])
    @country.hide(@current_user)
    redirect_to countries_path
  end
end
