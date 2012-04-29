# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
module VendorsHelper
  def drawer_transaction_path(d,*args)
    return "/vendors/edit_drawer_transaction/#{d.id}"
  end
end
