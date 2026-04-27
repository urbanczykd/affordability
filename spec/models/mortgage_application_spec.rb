require "rails_helper"

RSpec.describe MortgageApplication, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:assessments).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:mortgage_application) }

    it { is_expected.to validate_presence_of(:annual_income) }
    it { is_expected.to validate_presence_of(:monthly_expenses) }
    it { is_expected.to validate_presence_of(:deposit_amount) }
    it { is_expected.to validate_presence_of(:property_value) }
    it { is_expected.to validate_presence_of(:term_years) }

    it { is_expected.to validate_numericality_of(:annual_income).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:monthly_expenses).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:deposit_amount).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:property_value).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:term_years).only_integer.is_greater_than(0).is_less_than_or_equal_to(40) }

    context "when deposit_amount equals property_value" do
      it "is invalid" do
        application = build(:mortgage_application, deposit_amount: 350_000, property_value: 350_000)
        expect(application).not_to be_valid
        expect(application.errors[:deposit_amount]).to include("must be less than the property value")
      end
    end

    context "when deposit_amount exceeds property_value" do
      it "is invalid" do
        application = build(:mortgage_application, deposit_amount: 400_000, property_value: 350_000)
        expect(application).not_to be_valid
        expect(application.errors[:deposit_amount]).to include("must be less than the property value")
      end
    end

    context "when deposit_amount is less than property_value" do
      it "is valid" do
        application = build(:mortgage_application, deposit_amount: 50_000, property_value: 350_000)
        expect(application).to be_valid
      end
    end

    context "with negative annual_income" do
      it "is invalid" do
        application = build(:mortgage_application, annual_income: -1000)
        expect(application).not_to be_valid
        expect(application.errors[:annual_income]).to be_present
      end
    end

    context "with zero property_value" do
      it "is invalid" do
        application = build(:mortgage_application, property_value: 0)
        expect(application).not_to be_valid
      end
    end

    context "with term_years exceeding 40" do
      it "is invalid" do
        application = build(:mortgage_application, term_years: 41)
        expect(application).not_to be_valid
        expect(application.errors[:term_years]).to be_present
      end
    end

    context "with a valid complete record" do
      it "is valid" do
        application = build(:mortgage_application)
        expect(application).to be_valid
      end
    end
  end

  describe "UUID primary key" do
    it "generates a UUID on create" do
      application = create(:mortgage_application)
      expect(application.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end
  end
end
