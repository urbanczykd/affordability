module Api
  module V1
    class MortgageApplicationsController < BaseController
      def create
        application = MortgageApplication.new(mortgage_application_params)

        if application.save
          render json: application_json(application), status: :created
        else
          render json: { error: "Validation failed", messages: application.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        application = MortgageApplication.find(params[:id])
        render json: application_json(application), status: :ok
      end

      private

      def mortgage_application_params
        params.require(:mortgage_application).permit(
          :annual_income,
          :monthly_expenses,
          :deposit_amount,
          :property_value,
          :term_years
        )
      end

      def application_json(application)
        {
          id: application.id,
          annual_income: application.annual_income,
          monthly_expenses: application.monthly_expenses,
          deposit_amount: application.deposit_amount,
          property_value: application.property_value,
          term_years: application.term_years,
          created_at: application.created_at,
          updated_at: application.updated_at
        }
      end
    end
  end
end
