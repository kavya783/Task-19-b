class Seller < ApplicationRecord
  validates :phone, presence: true
  validates :name, presence: true
  validates :email, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "phone",
      "name",
      "email",
      "created_at",
      "updated_at"
    ]
  end
end