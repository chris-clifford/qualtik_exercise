class CreateLoans < ActiveRecord::Migration[8.0]
  def change
    create_table :loans do |t|
      t.string :loan_number, null: false
      t.date :origination_date
      t.integer :amortization_period
      t.date :payment_date
      t.decimal :unpaid_principal_balance, precision: 15, scale: 2, null: false
      t.decimal :interest_rate, precision: 7, scale: 4, null: false
      t.decimal :net_operating_income, precision: 15, scale: 2
      t.boolean :is_interest_only

      t.timestamps
    end
  end
end
