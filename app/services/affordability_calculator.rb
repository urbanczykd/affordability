class AffordabilityCalculator
  Result = Struct.new(
    :loan_amount,
    :ltv,
    :dti_ratio,
    :max_borrowing,
    :monthly_payment,
    :decision,
    :explanation,
    keyword_init: true
  )

  MAX_LTV = 90.0
  MAX_DTI = 43.0
  INCOME_MULTIPLE = 4.5
  ASSUMED_ANNUAL_RATE = 3.5

  def initialize(mortgage_application)
    @app = mortgage_application
  end

  def calculate
    loan_amount   = compute_loan_amount
    ltv           = compute_ltv(loan_amount)
    dti_ratio     = compute_dti_ratio
    max_borrowing = compute_max_borrowing
    monthly_payment = compute_monthly_payment(loan_amount)
    decision, explanation = evaluate(loan_amount, ltv, dti_ratio, max_borrowing)

    Result.new(
      loan_amount: loan_amount.round(2),
      ltv: ltv.round(2),
      dti_ratio: dti_ratio.round(2),
      max_borrowing: max_borrowing.round(2),
      monthly_payment: monthly_payment.round(2),
      decision: decision,
      explanation: explanation
    )
  end

  private

  def compute_loan_amount
    @app.property_value.to_f - @app.deposit_amount.to_f
  end

  def compute_ltv(loan_amount)
    return 0.0 if @app.property_value.to_f.zero?

    (loan_amount / @app.property_value.to_f) * 100
  end

  def compute_dti_ratio
    monthly_income = @app.annual_income.to_f / 12
    return 0.0 if monthly_income.zero?

    (@app.monthly_expenses.to_f / monthly_income) * 100
  end

  def compute_max_borrowing
    income_cap = @app.annual_income.to_f * INCOME_MULTIPLE
    ltv_cap    = @app.property_value.to_f * (MAX_LTV / 100)
    [income_cap, ltv_cap].min
  end

  def compute_monthly_payment(loan_amount)
    return 0.0 if loan_amount <= 0

    monthly_rate = (ASSUMED_ANNUAL_RATE / 100) / 12
    n = @app.term_years.to_i * 12

    if monthly_rate.zero?
      loan_amount / n
    else
      loan_amount * (monthly_rate * (1 + monthly_rate)**n) / ((1 + monthly_rate)**n - 1)
    end
  end

  def evaluate(loan_amount, ltv, dti_ratio, max_borrowing)
    reasons = []

    reasons << "Loan-to-value ratio of #{ltv.round(1)}% exceeds the maximum allowed #{MAX_LTV}%." if ltv > MAX_LTV
    reasons << "Debt-to-income ratio of #{dti_ratio.round(1)}% exceeds the maximum allowed #{MAX_DTI}%." if dti_ratio > MAX_DTI
    reasons << "Requested loan amount of #{format_currency(loan_amount)} exceeds maximum borrowing of #{format_currency(max_borrowing)}." if loan_amount > max_borrowing
    reasons << "Loan amount must be greater than zero." if loan_amount <= 0

    if reasons.empty?
      explanation = "Application approved. Loan amount of #{format_currency(loan_amount)} " \
                    "with LTV of #{ltv.round(1)}% and DTI ratio of #{dti_ratio.round(1)}% " \
                    "meets all lending criteria."
      ["approved", explanation]
    else
      explanation = "Application declined. " + reasons.join(" ")
      ["declined", explanation]
    end
  end

  def format_currency(amount)
    "£#{"%.2f" % amount}"
  end
end
