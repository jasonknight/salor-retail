class AddImages < ActiveRecord::Migration
  def up
    create_table "images", :force => true do |t|
      t.string   "name"
      t.string   "imageable_type"
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
      t.integer  "imageable_id"
      t.integer  "company_id"
      t.integer  "vendor_id"
      t.string   "image_type"
      t.boolean  "hidden"
      t.integer  "hidden_by"
      t.datetime "hidden_at"
    end
  end

  def down
  end
end
