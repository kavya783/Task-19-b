class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true
      t.string :txnid, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "pending"
      t.text :items, null: false, default: "[]"

      t.timestamps
    end

    add_index :orders, :txnid, unique: true
  end
end