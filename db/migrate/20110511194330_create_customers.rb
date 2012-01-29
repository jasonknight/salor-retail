class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.string :first_name
      t.string :last_name
      t.string :street1
      t.string :street2
      t.string :postalcode
      t.string :state
      t.string :country
      t.string :city
      t.string :telephone
      t.string :cellphone
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :customers
  end
end
