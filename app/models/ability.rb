# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Ability
  def initialize(user)
    can :manage, :all if user.is_owner?
    can :read, :all
  end
end
