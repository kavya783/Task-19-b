class AddFieldsToContents < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :category, :string
    add_column :contents, :heading, :string
    add_column :contents, :subheading, :string
    add_column :contents, :description, :text
  end
end