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

ActiveRecord::Schema.define(version: 2026_05_20_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "care_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "caregiver_matching_infos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "coordinator_matching_infos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.datetime "updated_at", null: false
  end

  create_table "matching_info_care_types", force: :cascade do |t|
    t.bigint "care_type_id", null: false
    t.datetime "created_at", null: false
    t.bigint "matching_info_id", null: false
    t.string "matching_info_type", null: false
    t.datetime "updated_at", null: false
    t.index ["care_type_id"], name: "index_matching_info_care_types_on_care_type_id"
    t.index ["matching_info_type", "matching_info_id"], name: "idx_on_matching_info_type_matching_info_id_de942d05f3"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false, comment: "post title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "posts_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_posts_tags_on_post_id"
    t.index ["tag_id"], name: "index_posts_tags_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false, comment: "always lowercase"
    t.datetime "updated_at", null: false
  end

  create_table "user_images", comment: "uploaded image by user", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "image", null: false, comment: "Avatar image"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_images_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.date "birthday", null: false, comment: "Birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false, comment: "login email"
    t.string "name", null: false, comment: "nickname"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "audit_logs", "users"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "matching_info_care_types", "care_types"
  add_foreign_key "posts", "users"
  add_foreign_key "posts_tags", "posts"
  add_foreign_key "posts_tags", "tags"
  add_foreign_key "user_images", "users"
  add_foreign_key "user_profiles", "users"
end
