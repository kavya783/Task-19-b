class Api::V1::CouponsController < Api::BaseController
  def index
    coupons = Coupon.where(active: true)
                    .order(:id)
                    .select(:id, :code, :title, :saving, :discount, :minimum_amount, :details)

    render json: coupons
  end
end
