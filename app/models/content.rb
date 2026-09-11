class Content < ApplicationRecord
  has_one_attached :image

  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      category
      subcategory
      heading
      image_url
      subheading
      description
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end