require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  include ActionView::Helpers::NumberHelper

  test "index shows loans" do
    loan = loans(:one)

    get loans_url

    assert_response :success
    assert_includes @response.body, "Loans"
    assert_includes @response.body, loan.loan_number
    assert_includes @response.body, number_with_precision(loan.dscr, precision: 3)
  end

  test "import creates loans from csv" do
    file = fixture_file_upload("loans.csv", "text/csv")

    assert_difference("Loan.count", 2) do
      post import_loans_url, params: { file: file }
    end

    assert_redirected_to loans_url
    follow_redirect!

    assert_equal "Imported 2 loans.", flash[:notice]
    assert Loan.exists?(loan_number: "LOAN-003")
    assert Loan.exists?(loan_number: "LOAN-004")
  end

  test "import continues when rows are invalid and reports all failures" do
    file = fixture_file_upload("loans_with_invalid.csv", "text/csv")

    assert_difference("Loan.count", 2) do
      post import_loans_url, params: { file: file }
    end

    assert_redirected_to loans_url
    follow_redirect!

    assert_equal "Imported 2 loans.", flash[:notice]
    assert Loan.exists?(loan_number: "LOAN-005")
    assert Loan.exists?(loan_number: "LOAN-007")
    refute Loan.exists?(loan_number: "LOAN-006")

    assert_includes flash[:alert], "1 row"
    assert_includes flash[:alert], "LOAN-006"
    assert_match(/Interest rate/i, flash[:alert])
  end
end
