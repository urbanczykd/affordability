class CreateAssessments < ActiveRecord::Migration[7.2]
  def change
    create_table :assessments, id: :uuid do |t|
      t.references :mortgage_application, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "pending"
      t.string :decision
      t.decimal :loan_amount, precision: 15, scale: 2
      t.decimal :ltv, precision: 8, scale: 4
      t.decimal :dti_ratio, precision: 8, scale: 4
      t.decimal :max_borrowing, precision: 15, scale: 2
      t.decimal :monthly_payment, precision: 15, scale: 2
      t.text :explanation

      t.timestamps
    end

    add_index :assessments, :status
  end
end
