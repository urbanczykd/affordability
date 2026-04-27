require "rails_helper"

RSpec.describe AffordabilityCalculator do
  subject(:calculator) { described_class.new(mortgage_application) }

  let(:mortgage_application) { build(:mortgage_application, attributes) }

  shared_examples "returns a Result struct" do
    it "returns a Result struct" do
      result = calculator.calculate
      expect(result).to be_a(AffordabilityCalculator::Result)
    end

    it "populates all result fields" do
      result = calculator.calculate
      expect(result.loan_amount).to be_a(Numeric)
      expect(result.ltv).to be_a(Numeric)
      expect(result.dti_ratio).to be_a(Numeric)
      expect(result.max_borrowing).to be_a(Numeric)
      expect(result.monthly_payment).to be_a(Numeric)
      expect(result.decision).to be_in(%w[approved declined])
      expect(result.explanation).to be_a(String)
    end
  end

  describe "#calculate" do
    context "when all criteria are met (approved)" do
      let(:attributes) do
        {
          annual_income: 75_000,
          monthly_expenses: 1_500,
          deposit_amount: 50_000,
          property_value: 350_000,
          term_years: 25
        }
      end

      include_examples "returns a Result struct"

      it "returns approved decision" do
        expect(calculator.calculate.decision).to eq("approved")
      end

      it "calculates the correct loan_amount" do
        expect(calculator.calculate.loan_amount).to eq(300_000.0)
      end

      it "calculates the correct LTV" do
        # (300_000 / 350_000) * 100 = 85.71...
        expect(calculator.calculate.ltv).to be_within(0.01).of(85.71)
      end

      it "calculates the correct DTI ratio" do
        # (1_500 / (75_000 / 12)) * 100 = (1_500 / 6_250) * 100 = 24.0
        expect(calculator.calculate.dti_ratio).to be_within(0.01).of(24.0)
      end

      it "calculates max_borrowing as the income-capped value" do
        # income_cap = 75_000 * 4.5 = 337_500
        # ltv_cap    = 350_000 * 0.9 = 315_000
        # min = 315_000
        expect(calculator.calculate.max_borrowing).to eq(315_000.0)
      end

      it "calculates a positive monthly payment" do
        expect(calculator.calculate.monthly_payment).to be > 0
      end

      it "uses the standard amortization formula for monthly payment" do
        monthly_rate = (3.5 / 100) / 12
        n = 25 * 12
        loan = 300_000.0
        expected = loan * (monthly_rate * (1 + monthly_rate)**n) / ((1 + monthly_rate)**n - 1)
        expect(calculator.calculate.monthly_payment).to be_within(0.01).of(expected)
      end

      it "includes positive explanation text" do
        expect(calculator.calculate.explanation).to include("approved")
      end
    end

    context "when LTV exceeds 90% (declined-ltv)" do
      let(:attributes) do
        {
          annual_income: 100_000,
          monthly_expenses: 1_000,
          deposit_amount: 10_000,
          property_value: 350_000,
          term_years: 25
        }
      end

      include_examples "returns a Result struct"

      it "returns declined decision" do
        expect(calculator.calculate.decision).to eq("declined")
      end

      it "calculates LTV above 90" do
        # (340_000 / 350_000) * 100 = 97.14
        expect(calculator.calculate.ltv).to be > 90
      end

      it "mentions LTV in the explanation" do
        expect(calculator.calculate.explanation).to include("Loan-to-value ratio")
        expect(calculator.calculate.explanation).to include("90%")
      end
    end

    context "when DTI exceeds 43% (declined-dti)" do
      let(:attributes) do
        {
          annual_income: 30_000,
          monthly_expenses: 1_200,
          deposit_amount: 50_000,
          property_value: 200_000,
          term_years: 25
        }
      end

      include_examples "returns a Result struct"

      it "returns declined decision" do
        expect(calculator.calculate.decision).to eq("declined")
      end

      it "calculates DTI above 43" do
        # (1_200 / (30_000 / 12)) * 100 = (1_200 / 2_500) * 100 = 48.0
        expect(calculator.calculate.dti_ratio).to be > 43
      end

      it "mentions DTI in the explanation" do
        expect(calculator.calculate.explanation).to include("Debt-to-income ratio")
        expect(calculator.calculate.explanation).to include("43%")
      end
    end

    context "when loan amount exceeds income multiple cap (declined-income)" do
      let(:attributes) do
        {
          annual_income: 50_000,
          monthly_expenses: 1_000,
          deposit_amount: 10_000,
          property_value: 300_000,
          term_years: 25
        }
      end

      include_examples "returns a Result struct"

      it "returns declined decision" do
        expect(calculator.calculate.decision).to eq("declined")
      end

      it "calculates max_borrowing limited by income multiple" do
        # income_cap = 50_000 * 4.5 = 225_000
        # ltv_cap    = 300_000 * 0.9 = 270_000
        # min = 225_000
        expect(calculator.calculate.max_borrowing).to eq(225_000.0)
      end

      it "has loan_amount exceeding max_borrowing" do
        result = calculator.calculate
        expect(result.loan_amount).to be > result.max_borrowing
      end

      it "mentions max borrowing in the explanation" do
        expect(calculator.calculate.explanation).to include("maximum borrowing")
      end
    end

    context "multiple decline reasons" do
      let(:attributes) do
        {
          annual_income: 20_000,
          monthly_expenses: 900,
          deposit_amount: 5_000,
          property_value: 300_000,
          term_years: 25
        }
      end

      it "returns declined" do
        expect(calculator.calculate.decision).to eq("declined")
      end

      it "includes all relevant decline reasons in explanation" do
        explanation = calculator.calculate.explanation
        expect(explanation).to include("declined")
      end
    end

    context "edge case: zero monthly expenses" do
      let(:attributes) do
        {
          annual_income: 75_000,
          monthly_expenses: 0,
          deposit_amount: 50_000,
          property_value: 350_000,
          term_years: 25
        }
      end

      it "calculates DTI ratio of 0" do
        expect(calculator.calculate.dti_ratio).to eq(0.0)
      end

      it "is approved" do
        expect(calculator.calculate.decision).to eq("approved")
      end
    end

    context "edge case: exactly 90% LTV (boundary)" do
      let(:attributes) do
        {
          annual_income: 100_000,
          monthly_expenses: 1_000,
          deposit_amount: 35_000,
          property_value: 350_000,
          term_years: 25
        }
      end

      it "calculates LTV of exactly 90%" do
        # (315_000 / 350_000) * 100 = 90.0
        expect(calculator.calculate.ltv).to be_within(0.001).of(90.0)
      end

      it "approves at exactly 90% LTV" do
        expect(calculator.calculate.decision).to eq("approved")
      end
    end

    context "edge case: exactly 43% DTI (boundary)" do
      let(:attributes) do
        {
          annual_income: 75_000,
          monthly_expenses: 2_687.5,
          deposit_amount: 50_000,
          property_value: 350_000,
          term_years: 25
        }
      end

      it "calculates DTI of exactly 43%" do
        # (2_687.5 / (75_000 / 12)) * 100 = (2_687.5 / 6_250) * 100 = 43.0
        expect(calculator.calculate.dti_ratio).to be_within(0.01).of(43.0)
      end

      it "approves at exactly 43% DTI" do
        expect(calculator.calculate.decision).to eq("approved")
      end
    end

    context "edge case: very short term (1 year)" do
      let(:attributes) do
        {
          annual_income: 200_000,
          monthly_expenses: 1_000,
          deposit_amount: 200_000,
          property_value: 400_000,
          term_years: 1
        }
      end

      it "computes a very high monthly payment" do
        result = calculator.calculate
        expect(result.monthly_payment).to be > 16_000
      end
    end

    context "edge case: maximum 40 year term" do
      let(:attributes) do
        {
          annual_income: 75_000,
          monthly_expenses: 1_000,
          deposit_amount: 50_000,
          property_value: 350_000,
          term_years: 40
        }
      end

      it "computes a lower monthly payment than a 25-year term" do
        result_40 = calculator.calculate

        shorter_app = build(:mortgage_application, attributes.merge(term_years: 25))
        result_25 = described_class.new(shorter_app).calculate

        expect(result_40.monthly_payment).to be < result_25.monthly_payment
      end
    end
  end
end
