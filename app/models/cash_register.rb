# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class CashRegister < ActiveRecord::Base
  # {START}
	include SalorScope
	include SalorBase
  include SalorModel
  has_many :cash_register_dailies
  has_many :vendor_printers
  belongs_to :vendor
  has_many :orders
  has_many :meta
  has_many :drawer_transactions
  def end_of_day_report
    table = {}
    cats_tags = Category.cats_report($User.get_drawer.id)
    @orders = Order.by_vendor.by_user.where(:refunded => false,:drawer_id => $User.get_drawer.id,:paid => true,:created_at => Time.now.beginning_of_day..Time.now)
    paymentmethod_sums = Hash.new
    cashtotal = 0.0
    @orders.each do |o|
      cashtotal += o.get_drawer_add
      o.payment_methods.each do |pm|
        paymentmethod_sums[pm.name] ||= 0 if not pm.internal_type == 'InCash'
        paymentmethod_sums[pm.name] += pm.amount if not pm.internal_type == 'InCash'
        if pm.amount < 0 then
          #cash_total += pm.amount if pm.internal_type != 'InCash'
        end
      end
    end
    paymentmethod_sums[I18n.t("InCash")] = cashtotal
    cats_tags.merge!(paymentmethod_sums)
    return cats_tags
  end
  # {END}
end
