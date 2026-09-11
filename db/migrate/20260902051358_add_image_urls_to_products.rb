class AddImageUrlsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_urls, :text
  end
end
