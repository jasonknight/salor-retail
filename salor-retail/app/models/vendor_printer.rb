# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class VendorPrinter < ActiveRecord::Base
  include SalorScope
  include SalorModel
  belongs_to :vendor
  belongs_to :cash_register
  scope :by_vendor, lambda { where("vendor_id = ?", GlobalData.salor_user.meta.vendor_id)}
end
