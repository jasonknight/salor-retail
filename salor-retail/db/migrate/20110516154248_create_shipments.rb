class CreateShipments < ActiveRecord::Migration
  def self.up
    create_table :shipments do |t|
      t.string :receiver_id
      t.string :shipper_id
      t.string :shipper_type
      t.string :receiver_type
      t.float :price
      t.boolean :paid
      t.integer :user_id
      t.integer :employee_id
      t.string :status
      t.timestamps
    end
  end

  def self.down
    drop_table :shipments
  end
end
