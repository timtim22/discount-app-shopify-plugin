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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_02_10_084934) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "old_prices", force: :cascade do |t|
    t.bigint "sale_id"
    t.string "product_id"
    t.json "variants"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "sale_id"], name: "index_old_prices_on_product_id_and_sale_id", unique: true
    t.index ["product_id"], name: "index_old_prices_on_product_id"
    t.index ["sale_id"], name: "index_old_prices_on_sale_id"
  end

  create_table "sale_collections", force: :cascade do |t|
    t.bigint "sale_id"
    t.json "collections"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sale_id"], name: "index_sale_collections_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "shop_id"
    t.string "title", null: false
    t.integer "sale_target", default: 0
    t.float "amount"
    t.integer "sale_type", default: 0
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "status", default: 1
    t.boolean "scheduled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_sales_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  create_table "tickets", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.text "query"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "old_prices", "sales"
  add_foreign_key "sale_collections", "sales"
end
