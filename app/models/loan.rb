class Loan < ApplicationRecord
  validates :loan_number, :unpaid_principal_balance, :interest_rate, presence: true

  def self.create_from_csv_row!(row)
    create!(attributes_from(row))
  end

  private

  def self.attributes_from(row)
    {
      loan_number: row["loan_number"]&.strip,
      origination_date: parse_date(row["origination_date"]),
      amortization_period: row["amortization_period"].presence&.to_i,
      payment_date: parse_date(row["payment_date"]),
      unpaid_principal_balance: row["unpaid_principal_balance"].presence&.to_d,
      interest_rate: row["interest_rate"].presence&.to_d,
      net_operating_income: row["net_operating_income"].presence&.to_d,
      is_interest_only: ActiveModel::Type::Boolean.new.cast(row["is_interest_only"])
    }
  end

  def self.parse_date(value)
    return if value.blank?

    Date.strptime(value, "%m/%d/%Y")
  rescue ArgumentError
    nil
  end

  private_class_method :attributes_from, :parse_date
end
