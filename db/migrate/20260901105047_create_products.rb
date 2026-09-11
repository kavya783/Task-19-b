
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :heading
      t.text :description
      t.decimal :price
      t.decimal :discount_price
      t.string :category

      t.timestamps
    end
  end
end
