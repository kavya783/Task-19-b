class AddReviewsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :reviews, :integer
  end
end
