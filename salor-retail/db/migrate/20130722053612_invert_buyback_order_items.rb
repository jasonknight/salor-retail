class InvertBuybackOrderItems < ActiveRecord::Migration
  def up
    # in SR up to August 2012, buyback OIs had a positive total. We need to invert them.
    Vendor.connection.execute("UPDATE order_items SET total_cents = -total_cents WHERE is_buyback IS TRUE AND total_cents > 0")
  end

  def down
  end
end
