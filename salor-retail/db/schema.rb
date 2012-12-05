# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121202085448) do

  create_table "actions", :force => true do |t|
    t.string   "name"
    t.text     "code"
    t.integer  "vendor_id"
    t.integer  "user_id"
    t.string   "whento"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "behavior"
    t.integer  "weight",     :default => 0
    t.string   "afield"
    t.float    "value",      :default => 0.0
    t.integer  "hidden",     :default => 0
    t.string   "field2"
    t.float    "value2"
    t.integer  "hidden_by"
  end

  add_index "actions", ["user_id"], :name => "index_actions_on_user_id"
  add_index "actions", ["vendor_id"], :name => "index_actions_on_vendor_id"

  create_table "broken_items", :force => true do |t|
    t.string   "name"
    t.string   "sku"
    t.float    "quantity"
    t.float    "base_price"
    t.integer  "vendor_id"
    t.integer  "owner_id"
    t.integer  "shipper_id"
    t.string   "owner_type"
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_shipment_item", :default => false
    t.integer  "hidden",           :default => 0
    t.integer  "hidden_by"
  end

  create_table "buttons", :force => true do |t|
    t.string   "name"
    t.string   "sku"
    t.string   "old_category_name"
    t.integer  "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
    t.boolean  "is_buyback",        :default => false
    t.integer  "category_id"
    t.string   "color"
    t.integer  "position"
    t.integer  "hidden",            :default => 0
  end

  create_table "cash_register_dailies", :force => true do |t|
    t.float    "start_amount"
    t.float    "end_amount"
    t.integer  "cash_register_id"
    t.integer  "employee_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logout_time"
  end

  add_index "cash_register_dailies", ["cash_register_id"], :name => "index_cash_register_dailies_on_cash_register_id"
  add_index "cash_register_dailies", ["employee_id"], :name => "index_cash_register_dailies_on_employee_id"
  add_index "cash_register_dailies", ["user_id"], :name => "index_cash_register_dailies_on_user_id"

  create_table "cash_registers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
    t.string   "scale"
    t.boolean  "hidden",                :default => false
    t.boolean  "paylife",               :default => false
    t.string   "bank_machine_path"
    t.string   "cash_drawer_path"
    t.boolean  "big_buttons",           :default => false
    t.boolean  "hide_discounts",        :default => false
    t.boolean  "no_print",              :default => false
    t.string   "thermal_printer",       :default => "/dev/usb/lp0"
    t.string   "sticker_printer",       :default => "/dev/usb/lp1"
    t.string   "a4_printer"
    t.string   "pole_display"
    t.string   "customer_screen_blurb"
    t.boolean  "salor_printer",         :default => true
    t.string   "color"
    t.string   "ip"
    t.boolean  "hide_buttons",          :default => true
    t.boolean  "show_plus_minus",       :default => true
    t.boolean  "detailed_edit"
  end

  add_index "cash_registers", ["vendor_id"], :name => "index_cash_registers_on_vendor_id"

  create_table "categories", :force => true do |t|
    t.integer  "vendor_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "quantity_sold",   :default => 0.0
    t.float    "cash_made"
    t.boolean  "eod_show",        :default => false
    t.string   "tag"
    t.boolean  "button_category"
    t.integer  "position"
    t.string   "color"
    t.string   "sku"
    t.integer  "hidden",          :default => 0
    t.integer  "hidden_by"
  end

  add_index "categories", ["vendor_id"], :name => "index_categories_on_vendor_id"

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.integer  "vendor_id"
    t.integer  "user_id"
    t.boolean  "hidden"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "hidden_by"
  end

  create_table "cues", :force => true do |t|
    t.boolean  "is_handled",      :default => false
    t.boolean  "to_send",         :default => false
    t.boolean  "to_receive",      :default => false
    t.text     "payload"
    t.string   "url"
    t.string   "source_sku"
    t.string   "destination_sku"
    t.string   "owner_type"
    t.integer  "owner_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "customers", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "street1"
    t.string   "street2"
    t.string   "postalcode"
    t.string   "state"
    t.string   "country"
    t.string   "city"
    t.string   "telephone"
    t.string   "cellphone"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
    t.string   "company_name"
    t.string   "sku"
    t.integer  "hidden",       :default => 0
    t.integer  "hidden_by"
    t.string   "tax_number"
  end

  add_index "customers", ["vendor_id"], :name => "index_customers_on_vendor_id"

  create_table "discounts", :force => true do |t|
    t.string   "name"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "vendor_id"
    t.integer  "category_id"
    t.integer  "location_id"
    t.string   "item_sku"
    t.string   "applies_to"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "amount"
    t.string   "amount_type"
    t.boolean  "hidden",      :default => false
    t.string   "sku"
    t.integer  "hidden_by"
  end

  add_index "discounts", ["amount_type"], :name => "index_discounts_on_amount_type"
  add_index "discounts", ["applies_to"], :name => "index_discounts_on_applies_to"
  add_index "discounts", ["category_id"], :name => "index_discounts_on_category_id"
  add_index "discounts", ["location_id"], :name => "index_discounts_on_location_id"
  add_index "discounts", ["vendor_id"], :name => "index_discounts_on_vendor_id"

  create_table "discounts_order_items", :id => false, :force => true do |t|
    t.integer "order_item_id"
    t.integer "discount_id"
  end

  add_index "discounts_order_items", ["order_item_id", "discount_id"], :name => "index_discounts_order_items_on_order_item_id_and_discount_id"

  create_table "discounts_orders", :id => false, :force => true do |t|
    t.integer "order_id"
    t.integer "discount_id"
  end

  add_index "discounts_orders", ["order_id", "discount_id"], :name => "index_discounts_orders_on_order_id_and_discount_id"

  create_table "drawer_transactions", :force => true do |t|
    t.integer  "drawer_id"
    t.float    "amount"
    t.boolean  "drop"
    t.boolean  "payout"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes"
    t.boolean  "is_refund",        :default => false
    t.string   "tag",              :default => "None"
    t.float    "drawer_amount",    :default => 0.0
    t.integer  "cash_register_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "order_id"
    t.integer  "order_item_id"
    t.integer  "vendor_id"
    t.boolean  "hidden"
    t.integer  "hidden_by"
  end

  add_index "drawer_transactions", ["drawer_id"], :name => "index_drawer_transactions_on_drawer_id"

  create_table "drawers", :force => true do |t|
    t.float    "amount",     :default => 0.0
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hidden",     :default => 0
  end

  add_index "drawers", ["owner_id"], :name => "index_drawers_on_owner_id"

  create_table "employees", :force => true do |t|
    t.string   "email",                                 :default => "",                :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",                :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.integer  "vendor_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "language"
    t.string   "theme"
    t.boolean  "js_keyboard",                           :default => false
    t.integer  "hidden",                                :default => 0
    t.string   "apitoken"
    t.integer  "uses_drawer_id"
    t.integer  "auth_code"
    t.string   "last_path",                             :default => "/cash_registers"
    t.string   "role_cache"
  end

  add_index "employees", ["email"], :name => "index_employees_on_email", :unique => true
  add_index "employees", ["reset_password_token"], :name => "index_employees_on_reset_password_token", :unique => true
  add_index "employees", ["user_id"], :name => "index_employees_on_user_id"
  add_index "employees", ["vendor_id"], :name => "index_employees_on_vendor_id"

  create_table "employees_roles", :id => false, :force => true do |t|
    t.integer "employee_id"
    t.integer "role_id"
  end

  add_index "employees_roles", ["employee_id", "role_id"], :name => "index_employees_roles_on_employee_id_and_role_id"

  create_table "errors", :force => true do |t|
    t.text     "msg"
    t.integer  "vendor_id"
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "applies_to_type"
    t.integer  "applies_to_id"
    t.boolean  "seen",            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.string   "referer"
  end

  create_table "histories", :force => true do |t|
    t.string   "url"
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "action_taken"
    t.string   "model_type"
    t.string   "ip"
    t.integer  "sensitivity"
    t.integer  "model_id"
    t.text     "changes_made"
    t.text     "params"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "invoice_blurbs", :force => true do |t|
    t.string   "lang"
    t.text     "body"
    t.boolean  "is_header"
    t.integer  "vendor_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.text     "body_receipt"
  end

  create_table "invoice_notes", :force => true do |t|
    t.string   "name"
    t.text     "note_header"
    t.text     "note_footer"
    t.integer  "origin_country_id"
    t.integer  "destination_country_id"
    t.integer  "vendor_id"
    t.integer  "user_id"
    t.boolean  "hidden"
    t.integer  "sale_type_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "item_types", :force => true do |t|
    t.string   "name"
    t.string   "behavior"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "sku"
    t.string   "image"
    t.integer  "vendor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "base_price",           :default => 0.0
    t.integer  "location_id"
    t.integer  "category_id"
    t.integer  "tax_profile_id"
    t.integer  "item_type_id"
    t.float    "amount_remaining",     :default => 0.0
    t.boolean  "activated",            :default => false
    t.integer  "void"
    t.integer  "coupon_type"
    t.string   "coupon_applies"
    t.float    "quantity",             :default => 0.0
    t.float    "quantity_sold",        :default => 0.0
    t.integer  "hidden",               :default => 0
    t.integer  "part_id"
    t.boolean  "calculate_part_price", :default => false
    t.float    "height",               :default => 0.0
    t.float    "weight",               :default => 0.0
    t.string   "height_metric"
    t.string   "weight_metric",        :default => "g"
    t.float    "length",               :default => 0.0
    t.float    "width",                :default => 0.0
    t.string   "length_metric"
    t.string   "width_metric"
    t.integer  "is_part"
    t.boolean  "is_gs1",               :default => false
    t.boolean  "price_by_qty"
    t.integer  "decimal_points"
    t.float    "part_quantity",        :default => 0.0
    t.string   "behavior"
    t.float    "tax_profile_amount",   :default => 0.0
    t.string   "sales_metric"
    t.float    "purchase_price",       :default => 0.0
    t.date     "expires_on"
    t.float    "buyback_price",        :default => 0.0
    t.integer  "quantity_buyback",     :default => 0
    t.boolean  "default_buyback",      :default => false
    t.float    "real_quantity",        :default => 0.0
    t.boolean  "weigh_compulsory",     :default => false
    t.float    "min_quantity",         :default => 0.0
    t.boolean  "active",               :default => true
    t.integer  "shipper_id"
    t.string   "shipper_sku"
    t.float    "packaging_unit",       :default => 1.0
    t.boolean  "ignore_qty",           :default => false
    t.integer  "child_id",             :default => 0
    t.boolean  "must_change_price",    :default => false
    t.boolean  "hidden_by_distiller",  :default => false
    t.boolean  "track_expiry",         :default => false
    t.string   "customs_code"
    t.float    "manufacturer_price"
    t.string   "origin_country"
    t.text     "name_translations"
    t.integer  "hidden_by"
  end

  add_index "items", ["category_id"], :name => "index_items_on_category_id"
  add_index "items", ["coupon_applies"], :name => "index_items_on_coupon_applies"
  add_index "items", ["coupon_type"], :name => "index_items_on_coupon_type"
  add_index "items", ["item_type_id"], :name => "index_items_on_item_type_id"
  add_index "items", ["location_id"], :name => "index_items_on_location_id"
  add_index "items", ["part_id"], :name => "index_items_on_part_id"
  add_index "items", ["sku"], :name => "index_items_on_sku"
  add_index "items", ["tax_profile_id"], :name => "index_items_on_tax_profile_id"
  add_index "items", ["vendor_id"], :name => "index_items_on_vendor_id"

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.float    "x"
    t.float    "y"
    t.string   "shape"
    t.integer  "vendor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "applies_to"
    t.float    "quantity_sold", :default => 0.0
    t.float    "cash_made",     :default => 0.0
    t.integer  "hidden",        :default => 0
    t.string   "sku",           :default => ""
    t.integer  "hidden_by"
  end

  add_index "locations", ["vendor_id"], :name => "index_locations_on_vendor_id"

  create_table "loyalty_cards", :force => true do |t|
    t.integer  "points"
    t.integer  "num_swipes"
    t.integer  "num_used"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sku"
    t.string   "customer_sku"
    t.integer  "hidden",       :default => 0
    t.integer  "vendor_id"
  end

  add_index "loyalty_cards", ["customer_id"], :name => "index_loyalty_cards_on_customer_id"
  add_index "loyalty_cards", ["sku"], :name => "index_loyalty_cards_on_sku"

  create_table "meta", :force => true do |t|
    t.integer  "vendor_id"
    t.integer  "crd_id"
    t.integer  "order_id"
    t.integer  "ownable_id"
    t.string   "ownable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cash_register_id"
    t.integer  "last_order_id"
    t.string   "color"
  end

  add_index "meta", ["cash_register_id"], :name => "index_meta_on_cash_register_id"
  add_index "meta", ["crd_id"], :name => "index_meta_on_crd_id"
  add_index "meta", ["order_id"], :name => "index_meta_on_order_id"
  add_index "meta", ["ownable_id"], :name => "index_meta_on_ownable_id"
  add_index "meta", ["ownable_type"], :name => "index_meta_on_ownable_type"
  add_index "meta", ["vendor_id"], :name => "index_meta_on_vendor_id"

  create_table "node_messages", :force => true do |t|
    t.string   "source_sku"
    t.string   "dest_sku"
    t.string   "mdhash"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "node_queues", :force => true do |t|
    t.boolean  "handled",         :default => false
    t.boolean  "send",            :default => false
    t.boolean  "receive",         :default => false
    t.text     "payload"
    t.string   "url"
    t.string   "source_sku"
    t.string   "destination_sku"
    t.string   "owner_type"
    t.integer  "owner_ir"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "nodes", :force => true do |t|
    t.string   "name"
    t.string   "sku"
    t.string   "token"
    t.string   "node_type"
    t.string   "url"
    t.boolean  "is_self"
    t.text     "accepted_ips"
    t.integer  "vendor_id"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "status"
    t.boolean  "is_busy",               :default => false
    t.integer  "hidden",                :default => 0
    t.boolean  "accepts_tax_profiles",  :default => true
    t.boolean  "accepts_buttons",       :default => true
    t.boolean  "accepts_categories",    :default => true
    t.boolean  "accepts_items",         :default => true
    t.boolean  "accepts_customers",     :default => true
    t.boolean  "accepts_loyalty_cards", :default => true
    t.boolean  "accepts_discounts",     :default => true
  end

  create_table "notes", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "notable_id"
    t.string   "notable_type"
    t.integer  "user_id"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["employee_id"], :name => "index_notes_on_employee_id"
  add_index "notes", ["notable_id"], :name => "index_notes_on_notable_id"
  add_index "notes", ["user_id"], :name => "index_notes_on_user_id"

  create_table "order_items", :force => true do |t|
    t.integer  "order_id"
    t.integer  "item_id"
    t.float    "quantity"
    t.float    "price",                 :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tax_profile_id"
    t.integer  "item_type_id"
    t.boolean  "activated",             :default => false
    t.boolean  "total_is_locked",       :default => false
    t.boolean  "tax_is_locked",         :default => false
    t.float    "total",                 :default => 0.0
    t.float    "tax",                   :default => 0.0
    t.float    "coupon_amount",         :default => 0.0
    t.string   "behavior"
    t.float    "tax_profile_amount",    :default => 0.0
    t.integer  "category_id"
    t.integer  "location_id"
    t.float    "amount_remaining",      :default => 0.0
    t.boolean  "refunded",              :default => false
    t.boolean  "discount_applied",      :default => false
    t.boolean  "coupon_applied",        :default => false
    t.datetime "refunded_at"
    t.integer  "refunded_by"
    t.string   "refunded_by_type"
    t.float    "discount_amount",       :default => 0.0
    t.float    "rebate",                :default => 0.0
    t.integer  "coupon_id",             :default => 0
    t.boolean  "is_buyback",            :default => false
    t.string   "sku"
    t.boolean  "weigh_compulsory",      :default => false
    t.boolean  "no_inc",                :default => false
    t.string   "refund_payment_method"
    t.boolean  "action_applied",        :default => false
    t.integer  "hidden",                :default => 0
    t.float    "rebate_amount",         :default => 0.0
    t.integer  "vendor_id"
    t.boolean  "tax_free",              :default => false
    t.integer  "hidden_by"
    t.integer  "employee_id"
    t.string   "name"
    t.string   "coupon_type"
    t.boolean  "must_change_price"
    t.string   "weight_metric"
    t.boolean  "calculate_part_price"
    t.string   "coupon_applies"
  end

  add_index "order_items", ["behavior"], :name => "index_order_items_on_behavior"
  add_index "order_items", ["category_id"], :name => "index_order_items_on_category_id"
  add_index "order_items", ["coupon_id"], :name => "index_order_items_on_coupon_id"
  add_index "order_items", ["is_buyback"], :name => "index_order_items_on_is_buyback"
  add_index "order_items", ["item_id"], :name => "index_order_items_on_item_id"
  add_index "order_items", ["item_type_id"], :name => "index_order_items_on_item_type_id"
  add_index "order_items", ["location_id"], :name => "index_order_items_on_location_id"
  add_index "order_items", ["order_id"], :name => "index_order_items_on_order_id"
  add_index "order_items", ["sku"], :name => "index_order_items_on_sku"
  add_index "order_items", ["tax_profile_id"], :name => "index_order_items_on_tax_profile_id"

  create_table "orders", :force => true do |t|
    t.float    "subtotal"
    t.float    "total"
    t.float    "tax"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
    t.integer  "user_id"
    t.integer  "location_id"
    t.integer  "paid"
    t.boolean  "refunded",               :default => false
    t.integer  "employee_id"
    t.integer  "hidden",                 :default => 0
    t.integer  "cash_register_id"
    t.integer  "customer_id"
    t.boolean  "total_is_locked",        :default => false
    t.boolean  "tax_is_locked",          :default => false
    t.boolean  "subtotal_is_locked",     :default => false
    t.integer  "cash_register_daily_id"
    t.float    "rebate",                 :default => 0.0
    t.string   "rebate_type",            :default => "percent"
    t.integer  "lc_points"
    t.float    "in_cash",                :default => 0.0
    t.float    "by_card",                :default => 0.0
    t.datetime "refunded_at"
    t.integer  "refunded_by"
    t.string   "refunded_by_type"
    t.float    "discount_amount",        :default => 0.0
    t.string   "tag"
    t.boolean  "buy_order",              :default => false
    t.float    "lc_discount_amount",     :default => 0.0
    t.text     "bk_msgs_received"
    t.string   "p_result"
    t.string   "p_text"
    t.text     "p_struct"
    t.text     "m_struct"
    t.text     "j_struct"
    t.text     "j_text"
    t.string   "j_ind"
    t.boolean  "was_printed"
    t.float    "front_end_change",       :default => 0.0
    t.string   "sku"
    t.integer  "drawer_id"
    t.boolean  "tax_free",               :default => false
    t.integer  "origin_country_id"
    t.integer  "destination_country_id"
    t.integer  "sale_type_id"
    t.text     "invoice_comment"
    t.text     "delivery_note_comment"
    t.integer  "nr"
    t.boolean  "is_proforma",            :default => false
    t.integer  "hidden_by"
  end

  add_index "orders", ["cash_register_daily_id"], :name => "index_orders_on_cash_register_daily_id"
  add_index "orders", ["cash_register_id"], :name => "index_orders_on_cash_register_id"
  add_index "orders", ["customer_id"], :name => "index_orders_on_customer_id"
  add_index "orders", ["employee_id"], :name => "index_orders_on_employee_id"
  add_index "orders", ["location_id"], :name => "index_orders_on_location_id"
  add_index "orders", ["user_id"], :name => "index_orders_on_user_id"
  add_index "orders", ["vendor_id"], :name => "index_orders_on_vendor_id"

  create_table "paylife_structs", :force => true do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.integer  "vendor_id"
    t.integer  "cash_register_id"
    t.integer  "order_id"
    t.text     "struct"
    t.text     "json"
    t.boolean  "tes",              :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sa"
    t.string   "ind"
  end

  create_table "payment_methods", :force => true do |t|
    t.string   "name"
    t.string   "internal_type"
    t.float    "amount",        :default => 0.0
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
  end

  add_index "payment_methods", ["order_id"], :name => "index_payment_methods_on_order_id"

  create_table "receipts", :force => true do |t|
    t.string   "ip"
    t.integer  "employee_id"
    t.integer  "cash_register_id"
    t.text     "content"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sale_types", :force => true do |t|
    t.string   "name"
    t.integer  "vendor_id"
    t.integer  "user_id"
    t.boolean  "hidden"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "hidden_by"
  end

  create_table "salor_configurations", :force => true do |t|
    t.integer  "vendor_id"
    t.float    "lp_per_dollar"
    t.float    "dollar_per_lp"
    t.text     "address"
    t.string   "telephone"
    t.text     "receipt_blurb"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pagination",            :default => 12
    t.string   "stylesheets"
    t.string   "cash_drawer"
    t.boolean  "open_cash_drawer",      :default => false
    t.datetime "last_wholesaler_check"
    t.text     "csv_imports"
    t.string   "csv_imports_url"
    t.string   "paylife_sa",            :default => "E"
    t.string   "paylife_version",       :default => "1"
    t.string   "paylife_euro"
    t.string   "paylife_konto",         :default => "01"
    t.string   "paylife_ind",           :default => "U"
    t.boolean  "auto_drop",             :default => false
    t.boolean  "items_view_list",       :default => true
    t.string   "url",                   :default => "http://salor"
    t.boolean  "salor_printer",         :default => false
    t.text     "receipt_blurb_footer"
    t.boolean  "calculate_tax",         :default => false
    t.boolean  "license_accepted",      :default => false
    t.boolean  "csv_categories"
    t.boolean  "csv_buttons"
    t.boolean  "csv_discounts"
    t.boolean  "csv_customers"
    t.boolean  "csv_loyalty_cards"
    t.text     "invoice_blurb"
    t.text     "invoice_blurb_footer"
  end

  add_index "salor_configurations", ["vendor_id"], :name => "index_configurations_on_vendor_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shipment_items", :force => true do |t|
    t.string   "name"
    t.float    "base_price"
    t.integer  "category_id"
    t.integer  "location_id"
    t.integer  "item_type_id"
    t.string   "sku"
    t.integer  "shipment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "in_stock",       :default => false
    t.float    "quantity"
    t.float    "purchase_price"
    t.boolean  "hidden"
    t.integer  "hidden_by"
    t.integer  "vendor_id"
  end

  add_index "shipment_items", ["category_id"], :name => "index_shipment_items_on_category_id"
  add_index "shipment_items", ["item_type_id"], :name => "index_shipment_items_on_item_type_id"
  add_index "shipment_items", ["location_id"], :name => "index_shipment_items_on_location_id"
  add_index "shipment_items", ["shipment_id"], :name => "index_shipment_items_on_shipment_id"

  create_table "shipment_items_stock_locations", :id => false, :force => true do |t|
    t.integer "shipment_item_id"
    t.integer "stock_location_id"
  end

  add_index "shipment_items_stock_locations", ["shipment_item_id", "stock_location_id"], :name => "shipment_items_stock"

  create_table "shipment_types", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hidden",     :default => 0
    t.integer  "vendor_id"
    t.integer  "hidden_by"
  end

  add_index "shipment_types", ["name"], :name => "index_shipment_types_on_name"
  add_index "shipment_types", ["user_id"], :name => "index_shipment_types_on_user_id"

  create_table "shipments", :force => true do |t|
    t.string   "receiver_id"
    t.string   "shipper_id"
    t.string   "shipper_type"
    t.string   "receiver_type"
    t.float    "price"
    t.boolean  "paid"
    t.integer  "user_id"
    t.integer  "employee_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "vendor_id"
    t.integer  "hidden",           :default => 0
    t.integer  "shipment_type_id"
    t.string   "sku"
    t.integer  "hidden_by"
  end

  add_index "shipments", ["employee_id"], :name => "index_shipments_on_employee_id"
  add_index "shipments", ["receiver_id"], :name => "index_shipments_on_receiver_id"
  add_index "shipments", ["shipper_id"], :name => "index_shipments_on_shipper_id"
  add_index "shipments", ["user_id"], :name => "index_shipments_on_user_id"
  add_index "shipments", ["vendor_id"], :name => "index_shipments_on_vendor_id"

  create_table "shippers", :force => true do |t|
    t.string   "name"
    t.string   "contact_person"
    t.string   "contact_phone"
    t.string   "contact_fax"
    t.string   "contact_email"
    t.integer  "user_id"
    t.integer  "employee_id"
    t.text     "contact_address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hidden",          :default => 0
    t.string   "reorder_type"
    t.string   "sku"
    t.integer  "vendor_id"
    t.integer  "hidden_by"
  end

  add_index "shippers", ["employee_id"], :name => "index_shippers_on_employee_id"
  add_index "shippers", ["user_id"], :name => "index_shippers_on_user_id"

  create_table "stock_locations", :force => true do |t|
    t.string   "name"
    t.integer  "vendor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden"
    t.integer  "hidden_by"
  end

  add_index "stock_locations", ["vendor_id"], :name => "index_stock_locations_on_vendor_id"

  create_table "tax_profiles", :force => true do |t|
    t.string   "name"
    t.float    "value"
    t.integer  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "hidden",     :default => 0
    t.string   "sku"
    t.integer  "vendor_id"
    t.string   "letter",     :default => "A"
    t.integer  "hidden_by"
  end

  add_index "tax_profiles", ["hidden"], :name => "index_tax_profiles_on_hidden"
  add_index "tax_profiles", ["user_id"], :name => "index_tax_profiles_on_user_id"

  create_table "tender_methods", :force => true do |t|
    t.string   "name"
    t.string   "internal_type"
    t.integer  "vendor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hidden",        :default => 0
    t.integer  "hidden_by"
  end

  create_table "transaction_tags", :force => true do |t|
    t.string   "name"
    t.integer  "vendor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "logo_image"
    t.string   "logo_image_content_type"
    t.boolean  "hidden"
    t.integer  "hidden_by"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",         :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",         :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "language"
    t.string   "theme"
    t.boolean  "js_keyboard",                           :default => false
    t.boolean  "is_technician"
    t.integer  "auth_code"
    t.string   "last_path",                             :default => "/vendors"
    t.string   "role_cache"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vendor_printers", :force => true do |t|
    t.string   "name"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vendor_id"
    t.integer  "cash_register_id"
    t.string   "printer_type"
    t.integer  "copies",           :default => 1
    t.integer  "codepage"
  end

  add_index "vendor_printers", ["cash_register_id"], :name => "index_vendor_printers_on_cash_register_id"
  add_index "vendor_printers", ["vendor_id"], :name => "index_vendor_printers_on_vendor_id"

  create_table "vendors", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hidden",                          :default => 0
    t.binary   "receipt_logo_header"
    t.binary   "receipt_logo_footer"
    t.string   "logo_image_content_type"
    t.binary   "logo_image"
    t.binary   "logo_invoice_image"
    t.binary   "logo_invoice_image_content_type"
    t.boolean  "multi_currency",                  :default => false
    t.string   "sku"
    t.string   "token"
    t.string   "email"
    t.boolean  "use_order_numbers",               :default => true
    t.string   "unused_order_numbers",            :default => "--- []\n"
    t.integer  "largest_order_number",            :default => 0
    t.integer  "hidden_by"
  end

  add_index "vendors", ["user_id"], :name => "index_vendors_on_user_id"

end
