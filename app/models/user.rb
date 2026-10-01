class User < ApplicationRecord

   has_many :orders, dependent: :nullify
  has_one :cart, dependent: :destroy
  has_many :cart_items, dependent: :destroy
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