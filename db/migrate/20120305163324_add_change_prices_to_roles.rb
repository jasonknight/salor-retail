class AddChangePricesToRoles < ActiveRecord::Migration
  def change
    [:clear_orders, :see_header,:destroy_order_items,:change_prices].each do |r|
      r = Role.find_or_create_by_name r.to_s
      r.save
    end
      [ :histories,
      :transaction_tags, :buttons, :stock_locations,:actions,:shipment_items].each do |r|
      [:index,:edit,:destroy,:create,:update,:show].each do |a|
        role = Role.find_or_create_by_name(a.to_s + '_' + r.to_s)
        role.save
      end
      role = Role.find_or_create_by_name('any_' + r.to_s)
      role.save
end

  end
end
