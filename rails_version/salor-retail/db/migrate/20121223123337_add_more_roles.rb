class AddMoreRoles < ActiveRecord::Migration
  def up
    [:destroy_order_items,
      :change_prices].each do |role|
      Role.find_or_create_by_name(role)
    end
  end

  def down
  end
end
