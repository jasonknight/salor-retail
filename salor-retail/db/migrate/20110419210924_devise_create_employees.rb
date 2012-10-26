class DeviseCreateEmployees < ActiveRecord::Migration
  def self.up
    create_table(:employees) do |t|
      t.string   "email",                                 :default => "",         :null => false
	t.string   "encrypted_password",     :limit => 128, :default => "",         :null => false
	t.string   "reset_password_token"
	t.datetime "reset_password_sent_at"
	t.datetime "remember_created_at"
	t.integer  "sign_in_count",                         :default => 0
	t.datetime "current_sign_in_at"
	t.datetime "last_sign_in_at"
	t.string   "current_sign_in_ip"
	t.string   "last_sign_in_ip"
	t.references :user
      # t.encryptable
      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable


      t.timestamps
    end

    add_index :employees, :email,                :unique => true
    add_index :employees, :reset_password_token, :unique => true
    # add_index :employees, :confirmation_token,   :unique => true
    # add_index :employees, :unlock_token,         :unique => true
    # add_index :employees, :authentication_token, :unique => true
  end

  def self.down
    drop_table :employees
  end
end
