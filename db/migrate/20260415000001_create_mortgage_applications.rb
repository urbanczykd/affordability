class CreateMortgageApplications < ActiveRecord::Migration[7.2]
  def change
    enable_extension "pgcrypto"

    create_table :mortgage_applications, id: :uuid do |t|
      t.decimal :annual_income, precision: 15, scale: 2, null: false
      t.decimal :monthly_expenses, precision: 15, scale: 2, null: false
      t.decimal :deposit_amount, precision: 15, scale: 2, null: false
      t.decimal :property_value, precision: 15, scale: 2, null: false
      t.integer :term_years, null: false

      t.timestamps
    end
  end
end
