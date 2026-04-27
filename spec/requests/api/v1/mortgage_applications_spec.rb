require "rails_helper"

RSpec.describe "Api::V1::MortgageApplications", type: :request do
  let(:valid_api_key) { "test-secret-key" }
  let(:headers) { { "Authorization" => "Bearer #{valid_api_key}", "Content-Type" => "application/json" } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("API_KEY").and_return(valid_api_key)
  end

  describe "POST /api/v1/mortgage_applications" do
    let(:valid_params) do
      {
        mortgage_application: {
          annual_income: 75_000,
          monthly_expenses: 1_500,
          deposit_amount: 50_000,
          property_value: 350_000,
          term_years: 25
        }
      }
    end

    context "with valid parameters and valid token" do
      it "creates a mortgage application and returns 201" do
        post "/api/v1/mortgage_applications", params: valid_params.to_json, headers: headers
        expect(response).to have_http_status(:created)
      end

      it "returns the created application in JSON" do
        post "/api/v1/mortgage_applications", params: valid_params.to_json, headers: headers
        json = JSON.parse(response.body)
        expect(json["annual_income"]).to eq("75000.0")
        expect(json["property_value"]).to eq("350000.0")
        expect(json["term_years"]).to eq(25)
        expect(json["id"]).to match(/\A[0-9a-f-]{36}\z/)
      end

      it "persists the record in the database" do
        expect {
          post "/api/v1/mortgage_applications", params: valid_params.to_json, headers: headers
        }.to change(MortgageApplication, :count).by(1)
      end
    end

    context "with invalid parameters" do
      it "returns 422 when annual_income is missing" do
        params = valid_params.deep_dup
        params[:mortgage_application].delete(:annual_income)
        post "/api/v1/mortgage_applications", params: params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error messages in JSON" do
        params = valid_params.deep_dup
        params[:mortgage_application][:annual_income] = -1000
        post "/api/v1/mortgage_applications", params: params.to_json, headers: headers
        json = JSON.parse(response.body)
        expect(json["messages"]).to be_an(Array)
        expect(json["messages"].first).to be_a(String)
      end

      it "returns 422 when deposit exceeds property value" do
        params = valid_params.deep_dup
        params[:mortgage_application][:deposit_amount] = 400_000
        post "/api/v1/mortgage_applications", params: params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 when term_years exceeds 40" do
        params = valid_params.deep_dup
        params[:mortgage_application][:term_years] = 45
        post "/api/v1/mortgage_applications", params: params.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not persist an invalid record" do
        params = valid_params.deep_dup
        params[:mortgage_application].delete(:property_value)
        expect {
          post "/api/v1/mortgage_applications", params: params.to_json, headers: headers
        }.not_to change(MortgageApplication, :count)
      end
    end

    context "authentication" do
      it "returns 401 when no Authorization header is provided" do
        post "/api/v1/mortgage_applications", params: valid_params.to_json,
          headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 when an invalid token is provided" do
        post "/api/v1/mortgage_applications", params: valid_params.to_json,
          headers: headers.merge("Authorization" => "Bearer wrong-token")
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 when Bearer prefix is missing" do
        post "/api/v1/mortgage_applications", params: valid_params.to_json,
          headers: headers.merge("Authorization" => valid_api_key)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/mortgage_applications/:id" do
    let!(:mortgage_application) { create(:mortgage_application) }

    context "with valid token and existing record" do
      it "returns 200 and the application" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(mortgage_application.id)
      end

      it "returns all expected fields" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}", headers: headers
        json = JSON.parse(response.body)
        expect(json.keys).to include("id", "annual_income", "monthly_expenses",
          "deposit_amount", "property_value", "term_years",
          "created_at", "updated_at")
      end
    end

    context "when the record does not exist" do
      it "returns 404" do
        get "/api/v1/mortgage_applications/00000000-0000-0000-0000-000000000000", headers: headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message in JSON" do
        get "/api/v1/mortgage_applications/00000000-0000-0000-0000-000000000000", headers: headers
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end

    context "authentication" do
      it "returns 401 with an invalid token" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}",
          headers: { "Authorization" => "Bearer bad-token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
