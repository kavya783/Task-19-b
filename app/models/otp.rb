class Otp < ApplicationRecord
  validates :phone, presence: true
  validates :otp, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "phone",
      "otp",
      "status",
      "expires_at",
      "created_at",
      "updated_at"
    ]
  end
end