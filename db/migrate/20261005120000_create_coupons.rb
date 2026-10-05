class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.string :saving, null: false
      t.integer :discount, null: false, default: 0
      t.integer :minimum_amount, null: false, default: 0
      t.text :details, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :coupons, :code, unique: true
  end
end
