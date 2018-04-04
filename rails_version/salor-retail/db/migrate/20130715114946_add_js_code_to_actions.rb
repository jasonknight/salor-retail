class AddJsCodeToActions < ActiveRecord::Migration
  def change
    add_column :actions, :js_code, :text
  end
end
