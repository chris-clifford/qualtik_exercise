class Loan < ApplicationRecord
  attr_accessor :origination_date_raw, :payment_date_raw, :is_interest_only_raw

  validates :loan_number, presence: true, length: { in: 2..50 }
  validates :amortization_period, numericality: { greater_than_or_equal_to: 0 }
  validates :unpaid_principal_balance, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :net_operating_income, numericality: { greater_than: 0 }
  validates :is_interest_only, inclusion: { in: [true, false] }

  validate :validate_date_formats
  validate :validate_payment_not_before_origination
  validate :validate_boolean_format

  def self.create_from_csv_row!(row)
    loan = new
    loan.assign_from_csv_row(row)
    loan.save!
    loan
  end

  def assign_from_csv_row(row)
    self.loan_number = row["loan_number"]&.strip
    self.origination_date_raw = row["origination_date"]
    self.origination_date = self.parse_date(origination_date_raw)
    self.amortization_period = row["amortization_period"].presence&.to_i
    self.payment_date_raw = row["payment_date"]
    self.payment_date = self.parse_date(payment_date_raw)
    self.unpaid_principal_balance = row["unpaid_principal_balance"].presence&.to_d
    self.interest_rate = row["interest_rate"].presence&.to_d
    self.net_operating_income = row["net_operating_income"].presence&.to_d
    self.is_interest_only_raw = row["is_interest_only"]
    self.is_interest_only = self.parse_boolean(is_interest_only_raw)
  end

  def debt_service_coverage_ratio
    net_operating_income / annual_debt_service
  end

  def annual_debt_service
    payment_amount * 12
  end

  def payment_amount
    (periodic_interest_rate * unpaid_principal_balance) / (1 - (1 + periodic_interest_rate) ** -number_of_periods.to_f)
  end

  def periodic_interest_rate
    interest_rate / 12
  end

  def number_of_periods
    months_between(payment_date, amortization_end_date)
  end

  def amortization_end_date
    origination_date + amortization_period.months
  end

  def months_between(date1, date2)
    (date2.year * 12 + date2.month) - (date1.year * 12 + date1.month)
  end

  private

  def parse_date(value)
    return if value.blank?

    Date.strptime(value, "%m/%d/%Y")
  rescue ArgumentError
    nil
  end

  def parse_boolean(value)
    return if value.nil?

    normalized = value.to_s.strip.downcase
    return true if normalized == "true"
    return false if normalized == "false"

    nil
  end

  def validate_date_formats
    if origination_date_raw.present? && origination_date.nil?
      errors.add(:origination_date, "must be in format MM/DD/YYYY")
    end

    if payment_date_raw.present? && payment_date.nil?
      errors.add(:payment_date, "must be in format MM/DD/YYYY")
    end
  end

  def validate_payment_not_before_origination
    return if payment_date.blank? || origination_date.blank?

    if payment_date < origination_date
      errors.add(:payment_date, "must be on or after origination_date")
    end
  end

  def validate_boolean_format
    if is_interest_only_raw.present? && is_interest_only.nil?
      errors.add(:is_interest_only, "must be \"true\" or \"false\"")
    end
  end
end
