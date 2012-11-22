SalorRetail::Application.routes.draw do
  resources :invoice_blurbs

  # The priority is based upon order of creation:
  # first created -> highest priority.

  match "vendors/csv" => "vendors#csv"
  match "vendors/backup" => "vendors#backup"
  match "nodes/send_msg" => "nodes#send_msg"
  match "nodes/receive_msg" => "nodes#receive_msg"
  match "home/index" => "home#index"
  match "home/exception_test" => "home#exception_test"
  match "home/set_user_theme_ajax" => "home#set_user_theme_ajax"
  match "home/user_employee_index" => "home#user_employee_index"
  match "home/set_language" => "home#set_language"
  match "buttons/position" => "buttons#position"
  match "categories/categories_json" => "categories#categories_json"
  match "categories/items_json" => "categories#items_json"
  match "orders/add_item_ajax" => "orders#add_item_ajax"
  match "orders/order_reports" => "orders#order_reports"
  match "orders/new_from_proforma" => "orders#new_from_proforma"
  match "orders/update_order_item" => "orders#update_order_item"
  match "orders/set_weight" => "orders#set_weight"
  match "orders/recently_tagged" => "orders#recently_tagged"
  match "orders/print_order_receipt" => "orders#print_order_receipt"
  match "orders/print_confirmed" => "orders#print_confirmed"
  match "orders/render_order_receipt" => "orders#render_order_receipt"
  match "orders/refund_item" => "orders#refund_item"
  match "orders/refund_order" => "orders#refund_order"
  match "orders/last_five_orders" => "orders#last_five_orders"
  match "orders/clear" => "orders#clear"
  match "orders/remove_payment_method" => "orders#remove_payment_method"
  match "orders/bancomat" => "orders#bancomat"
  match "orders/offline" => "orders#offline"
  match "order_items/index" => "order_items#index"
  match "reports/index" => "reports#selector"
  match "reports" => "reports#selector"
  match "items/search" => "items#search"
  match "items/export_broken_items" => "items#export_broken_items"
  match "items/report" => "items#report"
  match "items/update_location" => "items#update_location"
  match "items/reorder_recommendation" => "items#reorder_recommendation"
  match "items/update_location" => "items#update_location"
  match "items/update_real_quantity" => "items#update_real_quantity"
  match "items/update_real_quantity" => "items#update_real_quantity"
  match "items/move_real_quantity" => "items#move_real_quantity"
  match "items/labels" => "items#labels"
  match "customers/labels" => "customers#labels"
  match "items/selection" => "items#selection"
  match "items/upload" => "items#upload"
  match "items/upload" => "items#upload"
  match "items/upload_house_of_smoke" => "items#upload_house_of_smoke"
  match "items/upload_danczek_tobaccoland_plattner" => "items#upload_danczek_tobaccoland_plattner"
  match "items/upload_optimalsoft" => "items#upload_optimalsoft"
  get 'items/inventory_report'
  match "items/download" => "items#download"
  match "orders/new_pos" => "orders#new_pos"
  match "orders/swap" => "orders#swap"
  match "orders/prev_order" => "orders#prev_order"
  match "orders/show_payment_ajax" => "orders#show_payment_ajax"
  match "orders/complete_order_ajax" => "orders#complete_order_ajax"
  match "orders/new_order_ajax" => "orders#new_order_ajax"
  match "orders/activate_gift_card" => "orders#activate_gift_card"
  match "orders/update_order_items" => "orders#update_order_items"
  match "orders/update_pos_display" => "orders#update_pos_display"
  match "orders/delete_order_item" => "orders#delete_order_item"
  match "orders/connect_loyalty_card" => "orders#connect_loyalty_card"
  match "orders/split_order_item" => "orders#split_order_item"
  match "orders/print_receipt" => "orders#print_receipt"
  match "orders/void" => "orders#void"
  match "orders/report" => "orders#report"
  match "orders/report_range" => "orders#report_range"
  match "orders/report_day" => "orders#report_day"
  match "orders/report_day_range" => "orders#report_day_range"
  match "orders/:id/print" => "orders#print"
  match "orders/print" => "orders#print"
  match "orders/:id/customer_display" => 'orders#customer_display'
  match "vendors/:id/display_logo" => 'vendors#display_logo'
  match "employees/index" => "employees#index"
  match "items/info" => "items#info"
  match "items/item_json" => "items#item_json"
  match "items/wholesaler_update" => "items#wholesaler_update"
  match "items/database_distiller" => "items#database_distiller"
  match "items/distill_database" => "items#distill_database"
  match "cash_registers/end_of_day" => "cash_registers#end_of_day"

  match "items/create_ajax" => "items#create_ajax"
  match "vendors/edit_field_on_child" => "vendors#edit_field_on_child"
  match "vendors/toggle" => "vendors#toggle"
  match "vendors/destroy/:id" => "vendors#destroy"
  match "vendors/end_day" => "vendors#end_day"
  match "vendors/end_day" => "vendors#end_day"
  match "vendors/open_cash_drawer" => "vendors#open_cash_drawer"
  match "vendors/export" => "vendors#export"
  match "vendors/clearcache" => "vendors#clearcache"
  match "vendors/export" => "vendors#export"
  match "vendors/new_drawer_transaction" => "vendors#new_drawer_transaction"
  match "vendors/labels"
  match "vendors/spy" => "vendors#spy"
  match "api/order" => "api#order"
  match "vendors/help" => "vendors#help"
  match "shipments/move_all_to_items" => "shipments#move_all_to_items"
  match "shipments/new_shipments" => "shipments#new_shipments"
  match "shipments/move_shipment_item" => "shipments#move_shipment_item"
  match "home/load_clock" => "home#load_clock"
  match "home/backup_database" => "home#backup_database"
  match "home/errors_display" => "home#errors_display"
  match "home/backup_logfile" => "home#backup_logfile"
  match "home/remote_service" => 'home#remote_service'
  match "home/update_connection_status" => "home#update_connection_status"
  match "home/connect_remote_service" => "home#connect_remote_service"
  match "reports/selector" => "reports#selector"
  match "reports/daily" => "reports#daily"
  match "reports/cash_account" => "reports#cash_account"
  match "actions/create" => "actions#create"

  "authenticate,create,update,destroy,add_item".split(',').each do |u|
    post "api/#{u}"
  end
  
  %Q[search,time,registers,vendors,order,order_items,locations,categories,customers,discounts,items].split(',').each do |u|
    get "api/#{u}"
  end

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
  
  
  resources :tender_methods
  resources :reports
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
  resources :countries
  resources :invoice_notes
  resources :sale_types

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"
end
