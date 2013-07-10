class FixUserIdHash < ActiveRecord::Migration
  def up
    User.all.each do |u|
      u.set_id_hash
      u.save
    end
  end

  def down
  end
end
