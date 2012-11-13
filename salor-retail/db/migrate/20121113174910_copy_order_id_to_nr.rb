class CopyOrderIdToNr < ActiveRecord::Migration
  def up
    Order.connection.execute("UPDATE orders SET nr = id;")
  end

  def down
  end
end
