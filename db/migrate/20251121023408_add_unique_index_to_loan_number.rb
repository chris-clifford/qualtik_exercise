class AddUniqueIndexToLoanNumber < ActiveRecord::Migration[8.0]
  def change
    add_index :loans, :loan_number, unique: true
  end
end
