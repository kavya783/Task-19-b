class CreateMamaCashTransactions < ActiveRecord::Migration[8.1]
  def change
  create_table :mama_cash_transactions do |t|
    t.references :user, null: false, foreign_key: true
    t.references :order, foreign_key: true
    t.string :transaction_type, null: false
    t.decimal :amount, precision: 10, scale: 2, null: false
    t.string :status, null: false, default: "pending"

    t.timestamps
  end

  add_index :mama_cash_transactions,
            [:order_id, :transaction_type],
            unique: true,
            where: "order_id IS NOT NULL AND transaction_type = 'earned'",
            name: "index_unique_earned_mamacash_per_order"
end
end
