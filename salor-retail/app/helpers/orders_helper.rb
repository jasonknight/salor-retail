# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.
module OrdersHelper

  def format_item(item)
    item[:name] = item[:name][0..35]
    if item[:type] == 'integer'
      item[:price] = humanized_money_with_symbol item[:price].exchange_to(@ec) if item[:price]
      item[:total] = humanized_money_with_symbol item[:total].exchange_to(@ec) if item[:total]
      item[:quantity] = Integer(item[:quantity])
    elsif item[:type] == 'float'
      item[:price] = humanized_money_with_symbol item[:price].exchange_to(@ec) if item[:price]
      item[:total] = humanized_money_with_symbol item[:total].exchange_to(@ec) if item[:total]
      item[:quantity] = number_with_precision item[:quantity], :precision => 3
    elsif item[:type] == 'percent'
      item[:total] = humanized_money_with_symbol item[:total].exchange_to(@ec) if item[:total]
      item[:price] = number_to_percentage item[:price].exchange_to(@ec) if item[:price]
      item[:quantity] = Integer(item[:quantity])
    end
    return item
  end

  def format_tax(tax)
    tax[:value] = number_to_percentage tax[:value]
    tax[:net] = humanized_money_with_symbol tax[:net].exchange_to(@ec)
    tax[:tax] = humanized_money_with_symbol tax[:tax].exchange_to(@ec)
    tax[:gross] = humanized_money_with_symbol tax[:gross].exchange_to(@ec)
    return tax
  end
end
