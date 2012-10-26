class CreateCashRegisterDailies < ActiveRecord::Migration
  def self.up
    create_table :cash_register_dailies do |t|
      t.float :start_amount
      t.float :end_amount
      t.references :cash_register
      t.references :employee
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :cash_register_dailies
  end
end
