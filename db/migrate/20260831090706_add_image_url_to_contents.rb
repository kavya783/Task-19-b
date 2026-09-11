class AddImageUrlToContents < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :image_url, :string
  end
end
