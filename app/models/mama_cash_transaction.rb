
class MamaCashTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  TRANSACTION_TYPES = %w[earned redeemed].freeze
  STATUSES = %w[pending completed failed].freeze

  # Available balance =
  # Completed earnings - completed redemptions - pending reservations
  def self.available_balance_for(user_id)
    return BigDecimal("0") if user_id.blank?

    earned = where(
      user_id: user_id,
      transaction_type: "earned",
      status: "completed"
    ).sum(:amount)

    redeemed = where(
      user_id: user_id,
      transaction_type: "redeemed",
      status: "completed"
    ).sum(:amount)

    reserved = joins(:order).where(
      user_id: user_id,
      transaction_type: "redeemed",
      status: "pending",
      orders: { status: "pending" }
    ).sum(:amount)

    balance = earned - redeemed - reserved

    [balance, BigDecimal("0")].max
  end

  validates :transaction_type,
            inclusion: { in: TRANSACTION_TYPES }

  validates :status,
            inclusion: { in: STATUSES }

  validates :amount,
            numericality: { greater_than: 0 }

  validate :order_belongs_to_user

  private

  def order_belongs_to_user
    return if order.blank?
    return if order.user_id == user_id

    errors.add(:order, "must belong to the same user")
  end
end
