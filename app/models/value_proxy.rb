# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class ValueProxy
  @attrs = nil
  def initialize(attrs)
    @attrs = attrs
  end
  def method_missing(sym,*args,&block)
    syms = sym.to_s
    if @attrs[syms] then
      if @attrs[syms].class == Hash then
        return ValueProxy.new(@attrs[syms])
      else
        return @attrs[syms]
      end
    elsif @attrs[sym] then
      if @attrs[sym].class == Hash then
        return ValueProxy.new(@attrs[sym])
      else
        return @attrs[sym]
      end
      # do nothing
    end
  end
  end
