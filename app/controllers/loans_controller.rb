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
      Loan.create_from_csv_row!(row)
      imported_count += 1
    end

    imported_count
  end
end
