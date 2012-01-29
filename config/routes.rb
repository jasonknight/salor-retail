Salor::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :tender_methods
  resources :transaction_tags
  resources :buttons
  resources :broken_items
  resources :shipment_types
  resources :discounts
  resources :shippers
  resources :shipments
  resources :configurations
  resources :customers
  resources :cash_registers
  resources :item_types
  resources :tax_profiles
  resources :employees
  resources :actions
  resources :order_items
  resources :orders
  resources :items
  resources :locations
  resources :stock_locations
  resources :categories
  resources :vendors
  resources :nodes

  get "home/index"
  get "home/set_user_theme_ajax"
  get "home/user_employee_index"
  get "home/set_language"
  get "categories/categories_json"
  get "categories/items_json"
  get "orders/add_item_ajax"
  get "orders/update_order_item"
  put "orders/set_weight"
  get "orders/recently_tagged"
  get "orders/print_order_receipt"
  get "orders/render_order_receipt"
  get "orders/refund_item"
  get "orders/refund_order"
  get "orders/last_five_orders"
  get "orders/clear"
  get "orders/remove_payment_method"
  post "orders/bancomat"
  get "items/search"
  get "items/export_broken_items"
  post "items/export_broken_items"
  get "items/update_location"
  get "items/reorder_recommendation"
  post "items/update_location"
  get "items/update_real_quantity"
  post "items/update_real_quantity"
  get "items/move_real_quantity"
  post "items/labels"
  post "customers/labels"
  get "items/selection"
  get "items/upload"
  post "items/upload"
  post "items/upload_house_of_smoke"
  post "items/upload_danczek_tobaccoland_plattner"
  post "items/upload_optimalsoft"
  get 'items/inventory_report'
  get "items/download"
  get "orders/new_pos"
  get "orders/swap"
  get "orders/prev_order"
  get "orders/show_payment_ajax"
  get "orders/complete_order_ajax"
  get "orders/new_order_ajax"
  get "orders/activate_gift_card"
  get "orders/update_order_items"
  get "orders/update_pos_display"
  get "orders/delete_order_item"
  get "orders/connect_loyalty_card"
  get "orders/split_order_item"
  get "orders/print_receipt"
  get "orders/void"
  get "orders/report"
  get "orders/report_range"
  get "orders/report_day"
  get "orders/report_day_range"
  get "orders/:id/print" => "orders#print"
  get "orders/print"
  get "orders/:id/customer_display" => 'orders#customer_display'
  get "employees/index"
  get "items/info"
  get "items/item_json"
  get "items/wholesaler_update"
  get "cash_registers/end_of_day"

  post "items/create_ajax"
  post "vendors/edit_drawer_transaction"
  get "vendors/edit_field_on_child"
  get "vendors/toggle"
  get "vendors/end_day"
  post "vendors/end_day"
  get "vendors/open_cash_drawer"
  get "vendors/export"
  get "vendors/clearcache"
  get "vendors/list_drawer_transactions"
  post "vendors/export"
  post "vendors/new_drawer_transaction"
  post "vendors/edit_drawer_transaction"
  delete  "vendors/destroy_drawer_transaction"
  get  "vendors/labels"
  get "vendors/spy"
  get "api/order"
  get "vendors/help"
  get "shipments/move_all_to_items"
  get "shipments/move_shipment_item"
  get "home/load_clock"
  get "home/backup_database"
  get "home/backup_logfile"
  get "reports/selector"
  get "reports/daily"
  get "reports/cash_account"
  post "actions/create"

  "authenticate,create,update,destroy,add_item".split(',').each do |u|
    post "api/#{u}"
  end
  %Q[search,time,registers,vendors,order,order_items,locations,categories,customers,discounts,items].split(',').each do |u|
    get "api/#{u}"
  end

  match "vendors/edit_drawer_transaction/:id" => 'vendors#edit_drawer_transaction'
  match "vendors/destroy_drawer_transaction/:id" => 'vendors#destroy_drawer_transaction'
  match "vendors/render_end_of_day_receipt" => 'vendors#render_end_of_day_receipt'
  match "vendors/render_open_cashdrawer" => 'vendors#render_open_cashdrawer'
  match "vendors/render_drawer_transaction_receipt" => 'vendors#render_drawer_transaction_receipt'
  match "items/render_label" => "items#render_label"
  match "customers/render_label" => "customers#render_label"
  match "customers/upload_optimalsoft" => "customers#upload_optimalsoft"
  match 'vendors/:id/logo' => 'vendors#logo'
  match 'vendors/:id/logo_invoice' => 'vendors#logo_invoice'
  match 'transaction_tags/:id/logo' => 'transaction_tags#logo'
  match 'nodes/receive' => 'nodes#receive'
  match 'employees/login' => 'employees#login'
  match 'home/edit_owner' => 'home#edit_owner'
  match 'home/update_owner' => 'home#update_owner'
  match 'home/you_have_to_pay' => 'home#you_have_to_pay'

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
