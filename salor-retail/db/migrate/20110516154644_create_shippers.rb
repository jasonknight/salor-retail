class CreateShippers < ActiveRecord::Migration
  def self.up
    create_table :shippers do |t|
      t.string :name
      t.string :contact_person
      t.string :contact_phone
      t.string :contact_fax
      t.string :contact_email
      t.integer :user_id
      t.integer :employee_id
      t.text :contact_address

      t.timestamps
    end
  end

  def self.down
    drop_table :shippers
  end
end
