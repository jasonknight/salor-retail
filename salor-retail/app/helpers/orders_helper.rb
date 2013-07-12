# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
module OrdersHelper

  def format_item(item)
    item[:name] = item[:name][0..28]
    if item[:type] == 'integer'
      item[:price] = number_to_currency item[:price]
      item[:total] = number_to_currency item[:total]
      item[:quantity] = Integer(item[:quantity])
    elsif item[:type] == 'float'
      item[:price] = number_to_currency item[:price]
      item[:total] = number_to_currency item[:total]
      item[:quantity] = number_with_precision item[:quantity], :precision => 3
    elsif item[:type] == 'percent'
      item[:total] = number_to_currency item[:total]
      item[:price] = number_to_percentage item[:price]
      item[:quantity] = Integer(item[:quantity])
    end
    return item
  end

  def format_tax(tax)
    tax[:value] = number_to_percentage tax[:value]
    tax[:net] = number_to_currency tax[:net]
    tax[:tax] = number_to_currency tax[:tax]
    tax[:gross] = number_to_currency tax[:gross]
    return tax
  end
end
