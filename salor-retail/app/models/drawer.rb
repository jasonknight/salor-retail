# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Drawer < ActiveRecord::Base
  include SalorBase
  include SalorModel
  belongs_to :owner, :polymorphic => true
  has_many :orders
  has_many :drawer_transactions
  def add(num)
    self.update_attribute :amount, self.amount + num
  end

end
