class AddProductDetailsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :mrp, :decimal
    add_column :products, :sale_price, :decimal
    add_column :products, :discount_percentage, :decimal
    add_column :products, :rating, :decimal
    add_column :products, :net_content, :string
    add_column :products, :usp, :string
    add_column :products, :suitable_for, :string
    add_column :products, :benefits, :text
    add_column :products, :return_policy, :text
    add_column :products, :shipping_info, :text
  end
end
