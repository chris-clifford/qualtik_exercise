class LoansController < ApplicationController
  def index
    @loans = Loan.order(:loan_number)
  end

  def import
    if params[:file].blank?
      redirect_to loans_path, alert: "Please choose a CSV file to upload."
      return
    end

    imported_count = import_loans(params[:file])

    redirect_to loans_path, notice: "Imported #{imported_count} loan#{"s" unless imported_count == 1}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to loans_path, alert: "Import failed: #{e.message}"
  rescue CSV::MalformedCSVError => e
    redirect_to loans_path, alert: "Invalid CSV format: #{e.message}"
  rescue StandardError => e
    redirect_to loans_path, alert: "Import failed: #{e.message}"
  end

  private

  def import_loans(file)
    imported_count = 0
    csv_source = file.respond_to?(:tempfile) ? file.tempfile : file

    CSV.foreach(csv_source, headers: true) do |row|
      Loan.create!(attributes_from(row))
      imported_count += 1
    end

    imported_count
  end

  def attributes_from(row)
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

  def parse_date(value)
    return if value.blank?

    Date.strptime(value, "%m/%d/%Y")
  rescue ArgumentError
    nil
  end
end
