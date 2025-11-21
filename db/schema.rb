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

ActiveRecord::Schema[8.0].define(version: 2025_11_21_023408) do
  create_table "loans", force: :cascade do |t|
    t.string "loan_number", null: false
    t.date "origination_date"
    t.integer "amortization_period"
    t.date "payment_date"
    t.decimal "unpaid_principal_balance", precision: 15, scale: 2, null: false
    t.decimal "interest_rate", precision: 7, scale: 4, null: false
    t.decimal "net_operating_income", precision: 15, scale: 2
    t.boolean "is_interest_only"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "dscr", precision: 10, scale: 4
    t.index ["loan_number"], name: "index_loans_on_loan_number", unique: true
  end
end
