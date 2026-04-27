require "rails_helper"

RSpec.describe "Api::V1::Assessments", type: :request do
  let(:valid_api_key) { "test-secret-key" }
  let(:headers) { { "Authorization" => "Bearer #{valid_api_key}", "Content-Type" => "application/json" } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("API_KEY").and_return(valid_api_key)
  end

  let!(:mortgage_application) { create(:mortgage_application) }

  describe "POST /api/v1/mortgage_applications/:mortgage_application_id/assessments" do
    context "with valid token and existing mortgage application" do
      it "returns 202 Accepted" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
          headers: headers
        expect(response).to have_http_status(:accepted)
      end

      it "creates a pending assessment" do
        expect {
          post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
            headers: headers
        }.to change(Assessment, :count).by(1)

        expect(Assessment.last.status).to eq("pending")
        expect(Assessment.last.mortgage_application_id).to eq(mortgage_application.id)
      end

      it "enqueues the AffordabilityAssessmentJob" do
        expect {
          post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
            headers: headers
        }.to have_enqueued_job(AffordabilityAssessmentJob)
      end

      it "returns the assessment JSON with pending status" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
          headers: headers
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("pending")
        expect(json["id"]).to match(/\A[0-9a-f-]{36}\z/)
        expect(json["mortgage_application_id"]).to eq(mortgage_application.id)
      end

      it "returns null for uncomputed fields" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
          headers: headers
        json = JSON.parse(response.body)
        expect(json["decision"]).to be_nil
        expect(json["loan_amount"]).to be_nil
        expect(json["ltv"]).to be_nil
      end
    end

    context "when mortgage application does not exist" do
      it "returns 404" do
        post "/api/v1/mortgage_applications/00000000-0000-0000-0000-000000000000/assessments",
          headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "authentication" do
      it "returns 401 without a token" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
          headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 with an invalid token" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments",
          headers: headers.merge("Authorization" => "Bearer wrong-token")
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/mortgage_applications/:mortgage_application_id/assessments/:id" do
    context "when assessment is pending" do
      let!(:assessment) { create(:assessment, mortgage_application: mortgage_application, status: :pending) }

      it "returns 200 with pending status" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments/#{assessment.id}",
          headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("pending")
        expect(json["decision"]).to be_nil
      end
    end

    context "when assessment is completed and approved" do
      let!(:assessment) { create(:assessment, :completed, mortgage_application: mortgage_application) }

      it "returns 200 with all computed fields" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments/#{assessment.id}",
          headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("completed")
        expect(json["decision"]).to eq("approved")
        expect(json["loan_amount"]).to be_present
        expect(json["ltv"]).to be_present
        expect(json["dti_ratio"]).to be_present
        expect(json["max_borrowing"]).to be_present
        expect(json["monthly_payment"]).to be_present
        expect(json["explanation"]).to be_present
      end
    end

    context "when assessment is completed and declined" do
      let!(:assessment) { create(:assessment, :declined, mortgage_application: mortgage_application) }

      it "returns 200 with declined decision" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments/#{assessment.id}",
          headers: headers
        json = JSON.parse(response.body)
        expect(json["decision"]).to eq("declined")
      end
    end

    context "when assessment does not exist" do
      it "returns 404" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments/00000000-0000-0000-0000-000000000000",
          headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when assessment belongs to a different mortgage application" do
      let!(:other_application) { create(:mortgage_application) }
      let!(:assessment) { create(:assessment, mortgage_application: other_application) }

      it "returns 404" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments/#{assessment.id}",
          headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "authentication" do
      let!(:assessment) { create(:assessment, mortgage_application: mortgage_application) }

      it "returns 401 without a valid token" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}/assessments/#{assessment.id}",
          headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
