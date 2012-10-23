class ChangesToSchema < ActiveRecord::Migration
  def self.up
    begin
      change_column(:orders,:refunded,:boolean, :default => false)
      change_column(:order_items,:refunded,:boolean, :default => false)
      change_column(:order_items,:coupon_amount,:float, :default => 0)
      change_column(:order_items,:price,:float, :default => 0)
      change_column(:order_items,:tax,:float, :default => 0)
      change_column(:order_items,:total,:float, :default => 0)
      change_column(:order_items,:amount_remaining,:float, :default => 0)
      
      change_column(:items,:base_price,:float, :default => 0)
    rescue
      puts "ChangesToSchema Failed"
      puts $!
    end
  end

  def self.down
    puts "Nothin really to do"
  end
end
