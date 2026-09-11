class Product < ApplicationRecord
  serialize :image_urls, coder: JSON
  serialize :variants, coder: JSON
  serialize :benefits, coder: JSON

  # Temporary fields used only by ActiveAdmin form
  attr_accessor :variant_names,
                :variant_badges,
                :variant_mrps,
                :variant_sale_prices,
                :variant_discount_percentages,
                :variant_usps

  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "name",
      "heading",
      "description",
      "category",
      "status",
      "mrp",
      "sale_price",
      "discount_percentage",
      "rating",
      "net_content",
      "usp",
      "reviews",
      "benefits",
      "variants",
      "return_policy",
      "shipping_info",
      "created_at",
      "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end