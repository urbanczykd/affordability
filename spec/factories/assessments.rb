FactoryBot.define do
  factory :assessment do
    association :mortgage_application
    status { "pending" }

    trait :completed do
      status          { "completed" }
      decision        { "approved" }
      loan_amount     { 300_000.00 }
      ltv             { 85.71 }
      dti_ratio       { 24.00 }
      max_borrowing   { 315_000.00 }
      monthly_payment { 1_500.00 }
      explanation     { "Application approved. All criteria met." }
    end

    trait :declined do
      status          { "completed" }
      decision        { "declined" }
      loan_amount     { 345_000.00 }
      ltv             { 98.57 }
      dti_ratio       { 24.00 }
      max_borrowing   { 315_000.00 }
      monthly_payment { 1_700.00 }
      explanation     { "Application declined. LTV exceeds maximum." }
    end

    trait :failed do
      status { "failed" }
    end
  end
end
