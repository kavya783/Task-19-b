class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :user, optional: true

  validates :quantity, numericality: { greater_than: 0 }
end