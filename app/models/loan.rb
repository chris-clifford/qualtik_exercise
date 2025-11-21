class Loan < ApplicationRecord
  validates :loan_number, :unpaid_principal_balance, :interest_rate, presence: true
end
