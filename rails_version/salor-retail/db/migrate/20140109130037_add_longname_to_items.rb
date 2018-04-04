class AddLongnameToItems < ActiveRecord::Migration
  def change
    add_column :items, :longname, :string
  end
end
