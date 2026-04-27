require "rails_helper"

RSpec.describe Assessment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:mortgage_application) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enums" do
    it "defines status values" do
      expect(Assessment.statuses).to eq({
        "pending"   => "pending",
        "completed" => "completed",
        "failed"    => "failed"
      })
    end

    it "defaults to pending status" do
      assessment = build(:assessment)
      expect(assessment.status).to eq("pending")
    end
  end

  describe "UUID primary key" do
    it "generates a UUID on create" do
      assessment = create(:assessment)
      expect(assessment.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end
  end

  describe "status transitions" do
    let(:assessment) { create(:assessment) }

    it "can transition from pending to completed" do
      assessment.update!(status: :completed)
      expect(assessment).to be_completed
    end

    it "can transition from pending to failed" do
      assessment.update!(status: :failed)
      expect(assessment).to be_failed
    end
  end

  describe "scopes via enum" do
    it "finds pending assessments" do
      pending_assessment = create(:assessment, status: :pending)
      completed_assessment = create(:assessment, :completed)

      expect(Assessment.pending).to include(pending_assessment)
      expect(Assessment.pending).not_to include(completed_assessment)
    end

    it "finds completed assessments" do
      completed_assessment = create(:assessment, :completed)
      pending_assessment = create(:assessment, status: :pending)

      expect(Assessment.completed).to include(completed_assessment)
      expect(Assessment.completed).not_to include(pending_assessment)
    end
  end
end
