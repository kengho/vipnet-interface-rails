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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160922185757) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "coordinators", force: :cascade do |t|
    t.string   "vid"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "network_id"
  end

  add_index "coordinators", ["network_id"], name: "index_coordinators_on_network_id", using: :btree

  create_table "garlands", force: :cascade do |t|
    t.text    "entity"
    t.boolean "entity_type"
    t.string  "type"
    t.integer "next"
    t.integer "previous"
    t.integer "belongs_to_id"
    t.string  "belongs_to_type"
  end

  create_table "hw_nodes", force: :cascade do |t|
    t.string   "accessip"
    t.string   "version"
    t.string   "version_decoded"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "coordinator_id"
    t.integer  "ncc_node_id"
    t.string   "type"
  end

  add_index "hw_nodes", ["coordinator_id"], name: "index_hw_nodes_on_coordinator_id", using: :btree
  add_index "hw_nodes", ["ncc_node_id"], name: "index_hw_nodes_on_ncc_node_id", using: :btree

  create_table "ncc_nodes", force: :cascade do |t|
    t.string   "vid"
    t.string   "name"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.datetime "deletion_date"
    t.integer  "network_id"
    t.boolean  "enabled",                default: true
    t.string   "category"
    t.boolean  "creation_date_accuracy", default: true
    t.string   "abonent_number"
    t.string   "server_number"
    t.datetime "creation_date"
    t.string   "type"
    t.integer  "descendant_id"
  end

  add_index "ncc_nodes", ["network_id"], name: "index_ncc_nodes_on_network_id", using: :btree

  create_table "networks", force: :cascade do |t|
    t.string   "network_vid"
    t.string   "name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "node_ips", force: :cascade do |t|
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "u32",        limit: 8, null: false
    t.string   "type"
    t.integer  "hw_node_id"
  end

  add_index "node_ips", ["hw_node_id"], name: "index_node_ips_on_hw_node_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

  create_table "ticket_systems", force: :cascade do |t|
    t.string "url_template"
  end

  create_table "tickets", force: :cascade do |t|
    t.string   "vid"
    t.string   "ticket_id"
    t.integer  "ticket_system_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "ncc_node_id"
  end

  add_index "tickets", ["ncc_node_id"], name: "index_tickets_on_ncc_node_id", using: :btree
  add_index "tickets", ["ticket_system_id"], name: "index_tickets_on_ticket_system_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "role",                default: "user", null: false
    t.string   "email",                                null: false
    t.string   "crypted_password",                     null: false
    t.string   "password_salt",                        null: false
    t.string   "persistence_token",                    null: false
    t.string   "single_access_token",                  null: false
    t.string   "perishable_token",                     null: false
    t.integer  "login_count",         default: 0,      null: false
    t.integer  "failed_login_count",  default: 0,      null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
  end

  add_foreign_key "coordinators", "networks"
  add_foreign_key "hw_nodes", "coordinators"
  add_foreign_key "hw_nodes", "ncc_nodes"
  add_foreign_key "ncc_nodes", "networks"
  add_foreign_key "node_ips", "hw_nodes"
  add_foreign_key "tickets", "ncc_nodes"
  add_foreign_key "tickets", "ticket_systems"
end
