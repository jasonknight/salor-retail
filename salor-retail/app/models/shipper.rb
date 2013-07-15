# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Shipper < ActiveRecord::Base
	include SalorScope

  has_many :shipments, :as => :shipper
  has_many :returns, :as => :receiver
  has_many :items
  has_many :broken_items
  belongs_to :user
  belongs_to :vendor
  belongs_to :company
  validates_presence_of :name
  
  def fetch_csv
    file = SalorBase.get_url(self.csv_url)
    data = file.body
    return data
  end
  
  def import_csv(data)
    uploader = FileUpload.new(self, data)
    uploader.crunch
    return uploader
  end
  
  def fetch_and_import_csv
    data = self.fetch_csv
    uploader = self.import_csv(data)
    return uploader
  end
end


