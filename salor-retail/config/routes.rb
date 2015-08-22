SalorRetail::Application.routes.draw do
  
  match "users/signup" => "users#signup"
  match "users/clockin" => "users#clockin"
  match "users/clockout" => "users#clockout"
  match "users/verify" => "users#verify"
  match 'users/destroy_login' => 'users#destroy_login'
  match 'users/login' => 'users#login'
  
  match "vendors/csv" => "vendors#csv"
  match "vendors/backup" => "vendors#backup"
  match "vendors/history" => "vendors#history"
  match "vendors/:id/display_logo" => 'vendors#display_logo'
  match "vendors/edit_field_on_child" => "vendors#edit_field_on_child"
  match "vendors/get_configuration" => "vendors#get_configuration"
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
  match "vendors/render_report_day" => 'vendors#render_report_day'
  match "vendors/render_open_cashdrawer" => 'vendors#render_open_cashdrawer'
  match "vendors/render_drawer_transaction_receipt" => 'vendors#render_drawer_transaction_receipt'
  match 'vendors/:id/logo' => 'vendors#logo'
  match 'vendors/:id/logo_invoice' => 'vendors#logo_invoice'
  match "vendors/report_day" => "vendors#report_day"
  match "vendors/sales_statistics" => "vendors#sales_statistics"
  
  match "buttons/position" => "buttons#position"
  
  match "categories/categories_json" => "categories#categories_json"
  match "categories/items_json" => "categories#items_json"
  
  match "orders/complete" => "orders#complete"
  match "orders/receipts" => "orders#receipts"
  match "orders/undo_drawer_transaction" => "orders#undo_drawer_transaction"
  match "orders/add_item_ajax" => "orders#add_item_ajax"
  match "orders/order_reports" => "orders#order_reports"
  match "orders/merge_into_current_order" => "orders#merge_into_current_order"
  match "orders/new_from_proforma" => "orders#new_from_proforma"
  match "orders/update_order_item" => "orders#update_order_item"
  match "orders/set_weight" => "orders#set_weight"
  match "orders/recently_tagged" => "orders#recently_tagged"
  match "orders/print_order_receipt" => "orders#print_order_receipt"
  match "orders/print_confirmed" => "orders#print_confirmed"
  match "orders/render_order_receipt" => "orders#render_order_receipt"
  match "orders/last_five_orders" => "orders#last_five_orders"
  match "orders/clear" => "orders#clear"
  match "orders/remove_payment_method" => "orders#remove_payment_method"
  match "orders/bancomat" => "orders#bancomat"
  match "orders/offline" => "orders#offline"
  match "orders/new_pos" => "orders#new_pos"
  match "orders/swap" => "orders#swap"
  match "orders/prev_order" => "orders#prev_order"
  match "orders/show_payment_ajax" => "orders#show_payment_ajax"
  match "orders/new_order" => "orders#new_order"
  match "orders/activate_gift_card" => "orders#activate_gift_card"
  match "orders/update_order_items" => "orders#update_order_items"
  match "orders/update_pos_display" => "orders#update_pos_display"
  match "orders/delete_order_item" => "orders#delete_order_item"
  match "orders/connect_loyalty_card" => "orders#connect_loyalty_card"
  match "orders/print_receipt" => "orders#print_receipt"
  match "orders/void" => "orders#void"
  match "orders/:id/print" => "orders#print"
  match "orders/print" => "orders#print"
  match "orders/log" => "orders#log"
  match "orders/:id/customer_display" => 'orders#customer_display'
  match "orders/create_all_recurring" => "orders#create_all_recurring"
  
  
  
  match "reports/index" => "reports#index"
  match "reports" => "reports#index"
  match "reports/daily" => "reports#daily"
  match "reports/cash_account" => "reports#cash_account"
  
  
  
  match "customers/labels" => "customers#labels"
  match "customers/render_label" => "customers#render_label"
  match "customers/download" => "customers#download"
  match "customers/upload" => "customers#upload"
  match "customers/upload_optimalsoft" => "customers#upload_optimalsoft"
  
  

  match "cash_registers/end_of_day" => "cash_registers#end_of_day"

  
  
  
  match "items/search" => "items#search"
  match "items/report" => "items#report"
  match "items/export_broken_items" => "items#export_broken_items"
  match "items/reorder_recommendation" => "items#reorder_recommendation"
  match "items/update_location" => "items#update_location"
  match "items/move_real_quantity" => "items#move_real_quantity"
  match "items/labels" => "items#labels"
  match "items/selection" => "items#selection"
  match "items/upload" => "items#upload"
  match "items/upload_house_of_smoke" => "items#upload_house_of_smoke"
  match "items/upload_danczek_tobaccoland_plattner" => "items#upload_danczek_tobaccoland_plattner"
  match "items/upload_optimalsoft" => "items#upload_optimalsoft"
  match "items/download" => "items#download"
  match "items/info" => "items#info"
  match "items/gift_cards" => "items#gift_cards"
  match "items/create_ajax" => "items#create_ajax"
  match "items/render_label" => "items#render_label"
  
  
  
  match "inventory_reports/current" => "inventory_reports#current"
  match "inventory_reports/update_real_quantity" => "inventory_reports#update_real_quantity"
  match "inventory_reports/create_inventory_report" => "inventory_reports#create_inventory_report"
  match "inventory_reports/inventory_json" => "inventory_reports#inventory_json"
  

  

  
  match "shipments/move_all_items_into_stock" => "shipments#move_all_items_into_stock"
  match "shipments/new_shipments" => "shipments#new_shipments"
  match "shipments/move_item_into_stock" => "shipments#move_item_into_stock"
  match "shipments/add_item" => "shipments#add_item"
  
  match "shippers/update_all" => "shippers#update_all"
  
  match 'translations' => 'translations#index'
  match 'translations/set' => 'translations#set'
  
  
  match "actions/create" => "actions#create"
  match "plugins/create" => "plugins#create"

  
    
#   match "api/order" => "api#order"
#   "authenticate,create,update,destroy,add_item".split(',').each do |u|
#     post "api/#{u}"
#   end
#   %Q[search,time,registers,vendors,order,order_items,locations,categories,customers,discounts,items].split(',').each do |u|
#     get "api/#{u}"
#   end

  
  
  
  
  match 'transaction_tags/:id/logo' => 'transaction_tags#logo'
  
  
  
  match 'nodes/receive' => 'nodes#receive'

  resources :inventory_reports
  resources :invoice_blurbs
  resources :payment_methods
  resources :reports
  resources :transaction_tags
  resources :buttons
  resources :broken_items
  resources :shipment_types
  resources :discounts
  resources :shippers do
    post :upload
  end
  resources :shipments
  resources :configurations
  resources :customers
  resources :cash_registers
  resources :item_types
  resources :tax_profiles
  resources :users
  resources :actions
  resources :plugins
  resources :orders
  resources :items do
    get :new_action
  end
  resources :locations
  resources :stock_locations
  resources :categories
  resources :vendors
  resources :nodes
  resources :countries
  resources :invoice_notes
  resources :sale_types
  
  resource :session do
    get :test_exception
    post :email
    get :test_email
    get :remote_service
    get :connect_remote_service
    get :update_connection_status
    get :documentation
  end

  if defined?(SrSaas::Engine) == 'constant'
    mount SrSaas::Engine => "/saas"
    match '/signin' => 'sr_saas/sessions#new'
    match '*path' => 'sr_saas/sessions#new'
    root :to => 'orders#new'
  else
    match '*path' => 'sessions#new'
    root :to => 'orders#new'
  end
end
