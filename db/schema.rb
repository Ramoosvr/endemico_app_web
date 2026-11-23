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

ActiveRecord::Schema[8.1].define(version: 2026_11_23_173619) do
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

  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit", default: "pza", null: false
    t.decimal "stock", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "min_stock", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "cost_per_unit", precision: 10, scale: 2, default: "0.0", null: false
    t.string "supplier"
    t.index "LOWER(name)", name: "index_ingredients_on_lower_name", unique: true
  end

  create_table "option_choices", force: :cascade do |t|
    t.integer "option_group_id", null: false
    t.string "name", null: false
    t.decimal "extra_price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "default_selected", default: false, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["clip_request_id"], name: "index_orders_on_clip_request_id"
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
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["kind", "subkind"], name: "index_products_on_kind_and_subkind"
    t.index ["kind"], name: "index_products_on_kind"
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
  add_foreign_key "product_ingredients", "ingredients"
  add_foreign_key "product_ingredients", "products"
end
