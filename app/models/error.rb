# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Error < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  belongs_to :applies_to, :polymorphic => true
  include SalorBase
  include SalorScope
  include SalorModel
  before_create :set_model_owner
  before_create :set_url
  def set_url
    if GlobalData.request then
      self.url = GlobalData.request.url
      self.referer = GlobalData.request.referer
    end
  end
end
