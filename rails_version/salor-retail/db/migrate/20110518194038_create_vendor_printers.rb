class CreateVendorPrinters < ActiveRecord::Migration
  def self.up
    create_table :vendor_printers do |t|
      t.string :name
      t.string :path

      t.timestamps
    end
  end

  def self.down
    drop_table :vendor_printers
  end
end
