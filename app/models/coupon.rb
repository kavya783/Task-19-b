class Coupon < ApplicationRecord
  before_validation :normalize_code

  validates :code, :title, :saving, :details, presence: true
  validates :code, uniqueness: { case_sensitive: false }
  validates :discount, :minimum_amount,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id code title saving discount minimum_amount details active created_at updated_at]
  end

  private

  def normalize_code
    self.code = code.strip.upcase if code.present?
  end
end
