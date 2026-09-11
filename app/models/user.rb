class User < ApplicationRecord
  validates :phone, presence: true
 

  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "phone",
      "name",
      "email",
      "role",
      "created_at",
      "updated_at"
    ]
  end
end