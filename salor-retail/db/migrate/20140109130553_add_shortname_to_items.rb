class AddShortnameToItems < ActiveRecord::Migration
  def change
    add_column :items, :shortname, :string
  end
end
