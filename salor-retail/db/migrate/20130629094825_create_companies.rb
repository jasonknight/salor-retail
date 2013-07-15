class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :identifier
      t.string :mode
      t.string :subdomain
      t.boolean :hidden
      t.integer :hidden_by
      t.datetime :hidden_at
      t.boolean :active, :default => true
      t.string :email
      t.string :auth_user
      t.string :full_subdomain
      t.string :full_url
      t.string :virtualhost_filter
      t.integer :auth_https_mode
      t.boolean :https
      t.boolean :auth
      t.string :domain
      t.boolean :removal_pending

      t.timestamps
    end
  end
end
