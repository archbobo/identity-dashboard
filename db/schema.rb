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

ActiveRecord::Schema.define(version: 2020_06_11_125630) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "agencies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_agencies_on_name", unique: true
  end

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

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.text "description", default: ""
    t.integer "agency_id"
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "help_texts", force: :cascade do |t|
    t.bigint "service_provider_id"
    t.json "sign_in", default: {}
    t.json "sign_up", default: {}
    t.json "forgot_password", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_provider_id"], name: "index_help_texts_on_service_provider_id"
  end

  create_table "service_providers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "issuer", null: false
    t.string "friendly_name", null: false
    t.text "description"
    t.text "metadata_url"
    t.text "acs_url"
    t.text "assertion_consumer_logout_service_url"
    t.text "saml_client_cert"
    t.integer "block_encryption", default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: true, null: false
    t.boolean "approved", default: false, null: false
    t.text "sp_initiated_login_url"
    t.text "return_to_sp_url"
    t.integer "agency_id"
    t.json "attribute_bundle"
    t.integer "group_id"
    t.string "logo"
    t.integer "identity_protocol", default: 0
    t.json "redirect_uris"
    t.string "production_issuer"
    t.integer "ial"
    t.string "failure_to_proof_url"
    t.string "push_notification_url"
    t.jsonb "help_text", default: {"sign_in"=>{}, "sign_up"=>{}, "forgot_password"=>{}}
    t.string "remote_logo_key"
    t.index ["group_id"], name: "index_service_providers_on_group_id"
    t.index ["issuer"], name: "index_service_providers_on_issuer", unique: true
  end

  create_table "user_groups", force: :cascade do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_user_groups_on_group_id"
    t.index ["user_id"], name: "index_user_groups_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "uuid"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.boolean "admin", default: false, null: false
    t.integer "group_id"
    t.datetime "deleted_at"
    t.index ["email"], name: "index_users_on_email", where: "(deleted_at IS NULL)"
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["uuid"], name: "index_users_on_uuid", where: "(deleted_at IS NULL)"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "service_providers", "agencies"
  add_foreign_key "service_providers", "groups"
end
