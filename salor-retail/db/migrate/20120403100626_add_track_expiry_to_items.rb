class AddTrackExpiryToItems < ActiveRecord::Migration
  def change
    add_column :items, :track_expiry, :boolean, :default => false

  end
end
