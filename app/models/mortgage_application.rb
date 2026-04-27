class MortgageApplication < ApplicationRecord
  has_many :assessments, dependent: :destroy

  validates :annual_income, presence: true, numericality: { greater_than: 0 }
  validates :monthly_expenses, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :property_value, presence: true, numericality: { greater_than: 0 }
  validates :term_years, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 40 }

  validate :deposit_must_not_exceed_property_value

  private

  def deposit_must_not_exceed_property_value
    return unless deposit_amount.present? && property_value.present?

    if deposit_amount >= property_value
      errors.add(:deposit_amount, "must be less than the property value")
    end
  end
end
