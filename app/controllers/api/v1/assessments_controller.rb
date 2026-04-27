module Api
  module V1
    class AssessmentsController < BaseController
      before_action :set_mortgage_application

      def create
        assessment = @mortgage_application.assessments.create!(status: :pending)
        AffordabilityAssessmentJob.perform_later(assessment.id)

        render json: assessment_json(assessment), status: :accepted
      end

      def show
        assessment = @mortgage_application.assessments.find(params[:id])
        render json: assessment_json(assessment), status: :ok
      end

      private

      def set_mortgage_application
        @mortgage_application = MortgageApplication.find(params[:mortgage_application_id])
      end

      def assessment_json(assessment)
        {
          id: assessment.id,
          mortgage_application_id: assessment.mortgage_application_id,
          status: assessment.status,
          decision: assessment.decision,
          loan_amount: assessment.loan_amount,
          ltv: assessment.ltv,
          dti_ratio: assessment.dti_ratio,
          max_borrowing: assessment.max_borrowing,
          monthly_payment: assessment.monthly_payment,
          explanation: assessment.explanation,
          created_at: assessment.created_at,
          updated_at: assessment.updated_at
        }
      end
    end
  end
end
