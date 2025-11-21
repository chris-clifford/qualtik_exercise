class LoansController < ApplicationController
  def index
    @loans = Loan.order(:loan_number)
  end

  def import
    if params[:file].blank?
      redirect_to loans_path, alert: "Please choose a CSV file to upload."
      return
    end

    result = import_loans(params[:file])

    if result[:errors].any?
      flash[:alert] = build_import_errors_message(result[:errors], rolled_back: true)
    else
      flash[:notice] = "Imported #{result[:imported_count]} loan#{"s" unless result[:imported_count] == 1}."
    end

    redirect_to loans_path
  rescue CSV::MalformedCSVError => e
    redirect_to loans_path, alert: "Invalid CSV format: #{e.message}"
  rescue StandardError => e
    redirect_to loans_path, alert: "Import failed: #{e.message}"
  end

  private

  def import_loans(file)
    imported_count = 0
    errors = []
    csv_source = file.respond_to?(:tempfile) ? file.tempfile : file

    ActiveRecord::Base.transaction do
      CSV.foreach(csv_source, headers: true).with_index(2) do |row, line_number|
        begin
          Loan.create_from_csv_row!(row)
          imported_count += 1
        rescue ActiveRecord::RecordInvalid => e
          loan_number = row["loan_number"]&.strip
          loan_number = "row #{line_number}" if loan_number.blank?

          message = e.record&.errors&.full_messages&.to_sentence || e.message
          errors << { loan_number: loan_number, message: message }
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    imported_count = 0 if errors.any?

    { imported_count: imported_count, errors: errors }
  end

  def build_import_errors_message(errors, rolled_back:)
    failed_count = errors.size
    details = errors.map { |error| "#{error[:loan_number]}: #{error[:message]}" }.join("; ")

    prefix = rolled_back ? "Import canceled. " : ""

    "#{prefix}#{failed_count} row#{"s" unless failed_count == 1} failed - #{details}"
  end
end
