class FixNegOis < ActiveRecord::Migration
  def self.up
    OrderItem.where("total < 0").each do |oi|
      if oi.total < 0 then
        oi.update_attribute(:total, oi.total * -1)
        oi.order.update_self_and_save
      end
    end
    Order.where("total < 0").each do |oi|
      if oi.total < 0 then
        oi.update_attribute(:total, oi.total * -1)
        o.update_self_and_save
      end
    end
  end

  def self.down
  end
end
