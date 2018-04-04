# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class TransactionTag < ActiveRecord::Base
  include SalorScope
  include SalorBase

  belongs_to :vendor
  belongs_to :company
  
  validates_presence_of :vendor_id, :company_id, :name
end
