class AddHashToUsers < ActiveRecord::Migration
  def change
    add_column :users, :id_hash, :string
  end
end
