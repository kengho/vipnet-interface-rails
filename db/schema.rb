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

ActiveRecord::Schema.define(version: 20160527190315) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "coordinators", force: :cascade do |t|
    t.string   "vipnet_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "network_id"
  end

  add_index "coordinators", ["network_id"], name: "index_coordinators_on_network_id", using: :btree

  create_table "iplirconfs", force: :cascade do |t|
    t.integer  "coordinator_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.hstore   "sections"
    t.string   "content"
  end

  add_index "iplirconfs", ["coordinator_id"], name: "index_iplirconfs_on_coordinator_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.string   "source"
    t.string   "content"
    t.integer  "network_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "messages", ["network_id"], name: "index_messages_on_network_id", using: :btree

  create_table "networks", force: :cascade do |t|
    t.string   "vipnet_network_id"
    t.string   "name"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "nodenames", force: :cascade do |t|
    t.integer  "network_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.hstore   "records",    default: {}
    t.string   "content"
  end

  add_index "nodenames", ["network_id"], name: "index_nodenames_on_network_id", using: :btree

  create_table "nodes", force: :cascade do |t|
    t.string   "vipnet_id"
    t.string   "name"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.boolean  "history",                   default: false
    t.integer  "deleted_by_message_id"
    t.integer  "created_by_message_id"
    t.hstore   "ips",                       default: {},    null: false
    t.hstore   "vipnet_version",            default: {},    null: false
    t.datetime "created_first_at"
    t.datetime "deleted_at"
    t.integer  "network_id"
    t.boolean  "enabled"
    t.string   "category"
    t.boolean  "created_first_at_accuracy", default: true
    t.string   "abonent_number"
    t.string   "server_number"
    t.hstore   "tickets",                   default: {}
  end

  add_index "nodes", ["network_id"], name: "index_nodes_on_network_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

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
  add_foreign_key "messages", "networks"
  add_foreign_key "nodenames", "networks"
  add_foreign_key "nodes", "networks"
end
