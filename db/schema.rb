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

ActiveRecord::Schema[7.1].define(version: 2025_04_23_141522) do
  create_table "active_storage_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb3", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authorised_email_domains", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_authorised_email_domains_on_name", unique: true
  end

  create_table "certificates", charset: "utf8mb3", force: :cascade do |t|
    t.string "fingerprint"
    t.string "name"
    t.string "issuer"
    t.string "subject"
    t.datetime "not_before", precision: nil
    t.datetime "not_after", precision: nil
    t.string "serial"
    t.text "content"
    t.bigint "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fingerprint", "organisation_id"], name: "index_certificates_on_fingerprint_and_organisation_id", unique: true
    t.index ["name", "organisation_id"], name: "index_certificates_on_name_and_organisation_id", unique: true
  end

  create_table "custom_organisation_names", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "ips", charset: "utf8mb3", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "location_id"
    t.index ["address"], name: "index_ips_on_address", unique: true
    t.index ["location_id"], name: "index_ips_on_location_id"
  end

  create_table "locations", charset: "utf8mb3", force: :cascade do |t|
    t.string "radius_secret_key"
    t.string "address"
    t.string "postcode", null: false
    t.bigint "organisation_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["address", "organisation_id"], name: "index_locations_on_address_and_organisation_id", unique: true
    t.index ["organisation_id"], name: "index_locations_on_organisation_id"
  end

  create_table "memberships", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "organisation_id", null: false
    t.string "invitation_token"
    t.bigint "user_id", null: false
    t.integer "invited_by_id"
    t.datetime "confirmed_at", precision: nil
    t.boolean "can_manage_team", default: true, null: false
    t.boolean "can_manage_locations", default: true, null: false
    t.index ["organisation_id"], name: "index_memberships_on_organisation_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "mou_templates", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "mous", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "user_id"
    t.decimal "version", precision: 6, scale: 3
    t.string "job_role"
    t.string "name"
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_mous_on_organisation_id"
    t.index ["user_id"], name: "index_mous_on_user_id"
  end

  create_table "nominations", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "token"
    t.string "nominated_by"
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_nominations_on_organisation_id"
  end

  create_table "organisations", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "service_email"
    t.boolean "cba_enabled"
    t.index ["name"], name: "index_organisations_on_name", unique: true
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "mobile"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.integer "second_factor_attempts_count", default: 0
    t.string "encrypted_otp_secret_key"
    t.string "encrypted_otp_secret_key_iv"
    t.string "encrypted_otp_secret_key_salt"
    t.timestamp "totp_timestamp"
    t.boolean "is_super_admin", default: false, null: false
    t.string "direct_otp"
    t.datetime "direct_otp_sent_at", precision: nil
    t.boolean "sent_first_ip_survey", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_otp_secret_key"], name: "index_users_on_encrypted_otp_secret_key", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "mous", "organisations"
  add_foreign_key "mous", "users"
  add_foreign_key "nominations", "organisations"
end
