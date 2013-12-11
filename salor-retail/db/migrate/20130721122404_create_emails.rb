class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.string :sender
      t.string :receipient
      t.string :subject
      t.text :body
      t.boolean :technician
      t.integer :vendor_id
      t.integer :company_id
      t.integer :user_id
      t.integer :model_id
      t.integer :model_type
      t.boolean :hidden
      t.integer :hidden_by
      t.datetime :hidden_at

      t.timestamps
    end
  end
end
