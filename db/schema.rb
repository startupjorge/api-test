ActiveRecord::Schema[8.0].define(version: 2026_05_28_000001) do
  create_table "customer_accesses", force: :cascade do |t|
    t.string "email", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customer_accesses_on_email", unique: true
  end
end
