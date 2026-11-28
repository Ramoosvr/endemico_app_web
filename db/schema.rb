# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_28_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_messages", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "role", null: false
    t.text "content", default: "", null: false
    t.text "tool_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_agent_messages_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_agent_messages_on_user_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.string "name", null: false
    t.string "token_digest", null: false
    t.string "scopes", default: "read,write", null: false
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
  end

  create_table "cash_counts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "kind", null: false
    t.integer "d1", default: 0, null: false
    t.integer "d2", default: 0, null: false
    t.integer "d5", default: 0, null: false
    t.integer "d10", default: 0, null: false
    t.integer "d20", default: 0, null: false
    t.integer "d50", default: 0, null: false
    t.integer "d100", default: 0, null: false
    t.integer "d200", default: 0, null: false
    t.integer "d500", default: 0, null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shift"
    t.decimal "sold_cash", precision: 10, scale: 2, default: "0.0"
    t.decimal "sold_card", precision: 10, scale: 2, default: "0.0"
    t.decimal "sold_usd", precision: 10, scale: 2, default: "0.0"
    t.decimal "sold_transfer", precision: 10, scale: 2, default: "0.0"
    t.index ["kind", "created_at"], name: "index_cash_counts_on_kind_and_created_at"
    t.index ["shift"], name: "index_cash_counts_on_shift"
    t.index ["user_id"], name: "index_cash_counts_on_user_id"
  end

  create_table "cash_withdrawals", force: :cascade do |t|
    t.integer "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cash_withdrawals_on_user_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit", default: "pza", null: false
    t.decimal "stock", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "min_stock", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "cost_per_unit", precision: 10, scale: 2, default: "0.0", null: false
    t.string "supplier"
    t.string "external_id"
    t.string "category", default: "otros", null: false
    t.string "section"
    t.integer "section_position", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.string "brand"
    t.decimal "package_size", precision: 12, scale: 3
    t.string "package_unit"
    t.decimal "package_count", precision: 12, scale: 3
    t.decimal "package_price", precision: 10, scale: 2
    t.datetime "archived_at"
    t.decimal "unit_cost", precision: 16, scale: 6
    t.index "LOWER(name)", name: "index_ingredients_on_lower_name", unique: true
    t.index ["category"], name: "index_ingredients_on_category"
    t.index ["external_id"], name: "index_ingredients_on_external_id", unique: true
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.integer "ingredient_id", null: false
    t.integer "order_id"
    t.integer "order_item_id"
    t.integer "user_id"
    t.string "kind", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.decimal "stock_after", precision: 12, scale: 3
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_inventory_movements_on_ingredient_id"
    t.index ["kind", "created_at"], name: "index_inventory_movements_on_kind_and_created_at"
    t.index ["order_id"], name: "index_inventory_movements_on_order_id"
    t.index ["order_item_id"], name: "index_inventory_movements_on_order_item_id"
    t.index ["user_id"], name: "index_inventory_movements_on_user_id"
  end

  create_table "mermas", force: :cascade do |t|
    t.integer "ingredient_id", null: false
    t.integer "user_id", null: false
    t.decimal "amount", precision: 12, scale: 3, null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 12, scale: 2
    t.index ["created_at"], name: "index_mermas_on_created_at"
    t.index ["ingredient_id"], name: "index_mermas_on_ingredient_id"
    t.index ["user_id"], name: "index_mermas_on_user_id"
  end

  create_table "option_choice_ingredients", force: :cascade do |t|
    t.integer "option_choice_id", null: false
    t.integer "ingredient_id", null: false
    t.decimal "quantity_per_unit", precision: 10, scale: 3, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_option_choice_ingredients_on_ingredient_id"
    t.index ["option_choice_id", "ingredient_id"], name: "idx_oci_choice_ingredient", unique: true
    t.index ["option_choice_id"], name: "index_option_choice_ingredients_on_option_choice_id"
  end

  create_table "option_choices", force: :cascade do |t|
    t.integer "option_group_id", null: false
    t.string "name", null: false
    t.decimal "extra_price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "default_selected", default: false, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.boolean "available", default: true, null: false
    t.boolean "active", default: true, null: false
    t.integer "ingredient_id"
    t.index ["external_id"], name: "index_option_choices_on_external_id", unique: true
    t.index ["ingredient_id"], name: "index_option_choices_on_ingredient_id"
    t.index ["option_group_id"], name: "index_option_choices_on_option_group_id"
  end

  create_table "option_groups", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "name", null: false
    t.boolean "required", default: true, null: false
    t.string "selection_mode", default: "single", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.boolean "active", default: true, null: false
    t.index ["external_id"], name: "index_option_groups_on_external_id", unique: true
    t.index ["product_id"], name: "index_option_groups_on_product_id"
  end

  create_table "order_item_extras", force: :cascade do |t|
    t.integer "order_item_id", null: false
    t.integer "ingredient_id", null: false
    t.string "ingredient_name", null: false
    t.decimal "extra_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_order_item_extras_on_ingredient_id"
    t.index ["order_item_id", "ingredient_id"], name: "index_oi_extras_on_item_and_ingredient", unique: true
    t.index ["order_item_id"], name: "index_order_item_extras_on_order_item_id"
  end

  create_table "order_item_option_choices", force: :cascade do |t|
    t.integer "order_item_id", null: false
    t.integer "option_choice_id", null: false
    t.string "option_group_name", null: false
    t.string "choice_name", null: false
    t.decimal "extra_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity", default: 1, null: false
    t.index ["option_choice_id"], name: "index_order_item_option_choices_on_option_choice_id"
    t.index ["order_item_id", "option_choice_id"], name: "index_oi_choices_on_item_and_choice", unique: true
    t.index ["order_item_id"], name: "index_order_item_option_choices_on_order_item_id"
  end

  create_table "order_item_removed_ingredients", force: :cascade do |t|
    t.integer "order_item_id", null: false
    t.integer "ingredient_id", null: false
    t.string "ingredient_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_order_item_removed_ingredients_on_ingredient_id"
    t.index ["order_item_id", "ingredient_id"], name: "index_oi_removed_on_item_and_ingredient", unique: true
    t.index ["order_item_id"], name: "index_order_item_removed_ingredients_on_order_item_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "modifiers_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "line_total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.string "inventory_status"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", default: "open", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.string "clip_request_id"
    t.string "clip_status"
    t.datetime "clip_last_checked_at"
    t.decimal "usd_received", precision: 10, scale: 2
    t.decimal "usd_rate", precision: 8, scale: 4
    t.string "customer_name"
    t.decimal "cash_received", precision: 10, scale: 2
    t.datetime "prepared_at"
    t.datetime "refunded_at"
    t.text "refund_reason"
    t.integer "refunded_by_user_id"
    t.boolean "refund_prepared"
    t.index ["clip_request_id"], name: "index_orders_on_clip_request_id"
    t.index ["prepared_at"], name: "index_orders_on_prepared_at"
    t.index ["refunded_at"], name: "index_orders_on_refunded_at"
    t.index ["refunded_by_user_id"], name: "index_orders_on_refunded_by_user_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_ingredients", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "ingredient_id", null: false
    t.boolean "default_included", default: true, null: false
    t.decimal "extra_price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "quantity_per_unit", precision: 10, scale: 3, default: "0.0", null: false
    t.index ["ingredient_id"], name: "index_product_ingredients_on_ingredient_id"
    t.index ["product_id", "ingredient_id"], name: "index_product_ingredients_on_product_id_and_ingredient_id", unique: true
    t.index ["product_id"], name: "index_product_ingredients_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.decimal "cost", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subkind"
    t.boolean "featured", default: false, null: false
    t.string "external_id"
    t.boolean "active", default: true, null: false
    t.index ["external_id"], name: "index_products_on_external_id", unique: true
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["kind", "subkind"], name: "index_products_on_kind_and_subkind"
    t.index ["kind"], name: "index_products_on_kind"
  end

  create_table "recipe_lines", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "ingredient_id", null: false
    t.string "size"
    t.string "slot"
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_lines_on_ingredient_id"
    t.index ["product_id"], name: "index_recipe_lines_on_product_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "google_refresh_token"
    t.datetime "google_token_expires_at"
    t.string "role", default: "barista", null: false
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_messages", "users"
  add_foreign_key "cash_counts", "users"
  add_foreign_key "cash_withdrawals", "users"
  add_foreign_key "inventory_movements", "ingredients"
  add_foreign_key "inventory_movements", "users", on_delete: :nullify
  add_foreign_key "mermas", "ingredients"
  add_foreign_key "mermas", "users"
  add_foreign_key "option_choice_ingredients", "ingredients"
  add_foreign_key "option_choice_ingredients", "option_choices"
  add_foreign_key "option_choices", "option_groups"
  add_foreign_key "option_groups", "products"
  add_foreign_key "order_item_extras", "ingredients"
  add_foreign_key "order_item_extras", "order_items"
  add_foreign_key "order_item_option_choices", "option_choices"
  add_foreign_key "order_item_option_choices", "order_items"
  add_foreign_key "order_item_removed_ingredients", "ingredients"
  add_foreign_key "order_item_removed_ingredients", "order_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "refunded_by_user_id"
  add_foreign_key "product_ingredients", "ingredients"
  add_foreign_key "product_ingredients", "products"
  add_foreign_key "recipe_lines", "ingredients"
  add_foreign_key "recipe_lines", "products"
end
