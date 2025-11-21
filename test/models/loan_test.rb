require "test_helper"
require "csv"

class LoanTest < ActiveSupport::TestCase
  test "creates loan from valid csv row" do
    assert_difference("Loan.count", 1) do
      Loan.create_from_csv_row!(csv_row)
    end
  end

  test "rejects invalid origination date format" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Loan.create_from_csv_row!(csv_row(origination_date: "2020-01-15"))
    end

    assert_match(/Origination date must be in format MM\/DD\/YYYY/i, error.message)
  end

  test "requires payment date on or after origination date" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Loan.create_from_csv_row!(csv_row(origination_date: "03/01/2024", payment_date: "02/01/2024"))
    end

    assert_match(/Payment date must be on or after origination_date/i, error.message)
  end

  test "rejects invalid is_interest_only value" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Loan.create_from_csv_row!(csv_row(is_interest_only: "maybe"))
    end

    assert_match(/Is interest only must be \"true\" or \"false\"/i, error.message)
  end

  test "rejects numeric values outside constraints" do
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Loan.create_from_csv_row!(
        csv_row(
          amortization_period: "-5",
          unpaid_principal_balance: "-1",
          interest_rate: "-0.01",
          net_operating_income: "0"
        )
      )
    end

    assert_match(/Amortization period must be greater than or equal to 0/i, error.message)
    assert_match(/Unpaid principal balance must be greater than or equal to 0/i, error.message)
    assert_match(/Interest rate must be greater than or equal to 0/i, error.message)
    assert_match(/Net operating income must be greater than 0/i, error.message)
  end

  test "persists dscr on save" do
    loan = Loan.create_from_csv_row!(csv_row)

    loan.reload

    assert_in_delta loan.debt_service_coverage_ratio, loan.dscr, 0.0001
  end

  test "allows missing net operating income and leaves dscr nil" do
    loan = Loan.create_from_csv_row!(csv_row(net_operating_income: nil))

    assert_nil loan.dscr
  end

  test "handles non-positive number of periods when calculating dscr" do
    loan = Loan.create_from_csv_row!(
      csv_row(
        amortization_period: "0",
        origination_date: "01/15/2020",
        payment_date: "01/15/2020"
      )
    )

    assert_nil loan.dscr
  end

  private

  def csv_row(overrides = {})
    defaults = {
      "loan_number" => "LOAN-123",
      "origination_date" => "01/15/2020",
      "amortization_period" => "360",
      "payment_date" => "03/01/2024",
      "unpaid_principal_balance" => "450000.00",
      "interest_rate" => "0.045",
      "net_operating_income" => "65000.00",
      "is_interest_only" => "false"
    }.merge(overrides.stringify_keys)

    headers = defaults.keys
    CSV::Row.new(headers, headers.map { |key| defaults[key] })
  end
end
