class AllowGuestCarts < ActiveRecord::Migration[8.1]
  def change
    change_column_null :carts, :user_id, true
  end
endCartItem.columns_hash["user_id"].null

