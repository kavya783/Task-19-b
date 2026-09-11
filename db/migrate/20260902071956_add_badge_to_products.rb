class AddBadgeToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :badge, :string
  end
end
