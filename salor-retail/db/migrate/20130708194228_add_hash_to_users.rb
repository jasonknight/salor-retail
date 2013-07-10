class AddHashToUsers < ActiveRecord::Migration
  def change
    add_column :users, :id_hash, :string
    User.all.each do |u|
      u.set_id_hash
    end
  end
end
