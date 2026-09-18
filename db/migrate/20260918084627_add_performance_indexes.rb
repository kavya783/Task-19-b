class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :products, :category
    add_index :products, :created_at

    add_index :contents, :category

    add_index :orders, [:user_id, :created_at]

    add_index :otps, [:phone, :status, :created_at]
  end
end