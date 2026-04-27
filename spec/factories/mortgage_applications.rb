FactoryBot.define do
  factory :mortgage_application do
    annual_income    { 75_000.00 }
    monthly_expenses { 1_500.00 }
    deposit_amount   { 50_000.00 }
    property_value   { 350_000.00 }
    term_years       { 25 }

    trait :high_ltv do
      deposit_amount { 5_000.00 }
      property_value { 350_000.00 }
    end

    trait :high_dti do
      annual_income    { 30_000.00 }
      monthly_expenses { 1_200.00 }
    end

    trait :over_income_multiple do
      annual_income    { 50_000.00 }
      property_value   { 600_000.00 }
      deposit_amount   { 100_000.00 }
    end
  end
end
