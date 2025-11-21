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
    assert Loan.exists?(loan_number: "LOAN-001")
    assert Loan.exists?(loan_number: "LOAN-002")
  end
end
