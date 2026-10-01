class AddUserIdToCartItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :cart_items, :user, foreign_key: true
  end
end