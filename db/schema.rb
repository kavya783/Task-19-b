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

ActiveRecord::Schema[8.1].define(version: 2026_09_18_084627) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.integer "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "contents", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "heading"
    t.string "image"
    t.string "image_url"
    t.string "subcategory"
    t.string "subheading"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_contents_on_category"
  end

  create_table "orders", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "items", default: "[]", null: false
    t.string "status", default: "pending", null: false
    t.string "txnid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["txnid"], name: "index_orders_on_txnid", unique: true
    t.index ["user_id", "created_at"], name: "index_orders_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "otps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "otp"
    t.string "phone"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["phone", "status", "created_at"], name: "index_otps_on_phone_and_status_and_created_at"
  end

  create_table "products", force: :cascade do |t|
    t.string "badge"
    t.text "benefits"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "discount_percentage"
    t.integer "discount_price"
    t.string "heading"
    t.text "image_urls"
    t.decimal "mrp"
    t.string "name"
    t.string "net_content"
    t.integer "price"
    t.decimal "rating"
    t.text "return_policy"
    t.integer "reviews"
    t.decimal "sale_price"
    t.text "shipping_info"
    t.string "status"
    t.string "suitable_for"
    t.datetime "updated_at", null: false
    t.string "usp"
    t.text "variants"
    t.index ["category"], name: "index_products_on_category"
    t.index ["created_at"], name: "index_products_on_created_at"
  end

  create_table "sellers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "orders", "users"
end
