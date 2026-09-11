class AddSubcategoryToContents < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :subcategory, :string
  end
end
