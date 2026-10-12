class MamaCashTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  TRANSACTION_TYPES = %w[earned redeemed].freeze
  STATUSES = %w[pending completed failed].freeze

  def self.available_balance_for(user_id)
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

    [earned - redeemed - reserved, BigDecimal("0")].max
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
    return unless order && user_id != order.user_id

    errors.add(:order, "must belong to the same user")
  end
end