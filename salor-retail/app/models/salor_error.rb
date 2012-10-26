# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

module SalorError
  def add_salor_error(str)
    GlobalErrors.append(str,self)
  end
  def get_salor_errors
    errors = []
    GlobalErrors.get_errors.each do |e|
      if e[2] == self then
        errors << e[1]
      end
    end
    GlobalErrors.get_fatals.each do |e|
      if e[2] == self then
        errors << e[1]
      end
    end
    return errors
  end
end
