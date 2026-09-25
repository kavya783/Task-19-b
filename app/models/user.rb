class User < ApplicationRecord

  has_many :orders, dependent: :nullify

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

  def self.ransackable_associations(auth_object = nil)
    [
      "orders"
    ]
  end

end