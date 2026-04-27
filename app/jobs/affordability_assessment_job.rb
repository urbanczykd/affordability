class AffordabilityAssessmentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(assessment_id)
    assessment = Assessment.find(assessment_id)

    return if assessment.completed?

    mortgage_application = assessment.mortgage_application
    result = AffordabilityCalculator.new(mortgage_application).calculate

    assessment.update!(
      status: :completed,
      decision: result.decision,
      loan_amount: result.loan_amount,
      ltv: result.ltv,
      dti_ratio: result.dti_ratio,
      max_borrowing: result.max_borrowing,
      monthly_payment: result.monthly_payment,
      explanation: result.explanation
    )
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("AffordabilityAssessmentJob: Assessment #{assessment_id} not found - #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error("AffordabilityAssessmentJob: Failed for assessment #{assessment_id} - #{e.message}")
    assessment&.update(status: :failed)
    raise
  end
end
