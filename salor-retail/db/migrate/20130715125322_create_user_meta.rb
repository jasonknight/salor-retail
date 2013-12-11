class CreateUserMeta < ActiveRecord::Migration
  def change
    create_table :user_meta do |t|
      t.references :user
      t.string :key
      t.text :value

      t.timestamps
    end
    add_index :user_meta, :user_id
  end
end
