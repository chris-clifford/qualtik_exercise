class AddDscrToLoans < ActiveRecord::Migration[8.0]
  def change
    add_column :loans, :dscr, :decimal, precision: 10, scale: 4
  end
end
