module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_request

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def authenticate_request
        api_key = ENV["API_KEY"]
        token = extract_bearer_token

        if api_key.blank?
          render json: { error: "API authentication is not configured" }, status: :internal_server_error
        elsif token.blank? || token != api_key
          render json: { error: "Unauthorized. Valid Bearer token required." }, status: :unauthorized
        end
      end

      def extract_bearer_token
        auth_header = request.headers["Authorization"]
        return nil if auth_header.blank?

        match = auth_header.match(/\ABearer (.+)\z/i)
        match ? match[1] : nil
      end

      def not_found(exception)
        render json: { error: "Resource not found", message: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: "Validation failed", messages: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: "Bad request", message: exception.message }, status: :bad_request
      end
    end
  end
end
