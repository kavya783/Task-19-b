class ChangeProductPricesToInteger < ActiveRecord::Migration[8.1]
  def change
    change_column :products, :price, :integer
    change_column :products, :discount_price, :integer
  end
end