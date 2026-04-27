class Assessment < ApplicationRecord
  belongs_to :mortgage_application

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  validates :status, presence: true
  validates :mortgage_application, presence: true
end
