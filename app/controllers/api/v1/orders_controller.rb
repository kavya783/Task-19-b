class Api::V1::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  # ============================================================
  # USER ORDERS
  # GET /api/v1/users/:user_id/orders
  # ============================================================

  def index
    orders = Order
      .where(user_id: params[:user_id])
      .select(
        :id,
        :txnid,
        :amount,
        :status,
        :items,
        :created_at
      )
      .order(created_at: :desc)

    render json: orders.map { |order|
      {
        id: order.id,
        txnid: order.txnid,
        total: order.amount.to_f,
        status: order.status,
        items: order.items_data.map { |item| normalize_item(item) },
        created_at: order.created_at
      }
    }
  end

  # ============================================================
  # SELLER - ALL ORDERS
  # GET /api/v1/seller/orders
  # ============================================================

  def seller_orders
    orders = Order
  .where.not(user_id: nil)
  .includes(:user)
  .select(
    :id,
    :txnid,
    :amount,
    :status,
    :items,
    :user_id,
    :created_at
  )
  .order(created_at: :desc)

    render json: orders.map { |order|
      user = order.user

      {
        id: order.id,
        txnid: order.txnid,
        total: order.amount.to_f,
        status: order.status,
        created_at: order.created_at,

        customer: {
          id: user&.id,
          name: user&.name,
          email: user&.email,
          phone: user&.phone,
   
        },

        items: order.items_data.map do |item|
          normalize_item(item)
        end
      }
    }
  end

  # ============================================================
  # SELLER - UPDATE ORDER STATUS
  # PATCH /api/v1/seller/orders/:id/status
  # ============================================================

  def update_status
    order = Order.find(params[:id])

    allowed_statuses = [
      "pending",
      "shipped",
      "out_for_delivery",
      "delivered"
    ]

    new_status = params[:status].to_s.downcase

    unless allowed_statuses.include?(new_status)
      return render json: {
        error: "Invalid order status"
      }, status: :unprocessable_entity
    end

    order.update!(
      status: new_status
    )

    render json: {
      message: "Order status updated successfully",
      order: {
        id: order.id,
        txnid: order.txnid,
        total: order.amount.to_f,
        status: order.status
      }
    }, status: :ok
  end

  # ============================================================
  # DELETE ORDER
  # ============================================================

  def destroy
    order = Order.find(params[:id])
    order.destroy!

    render json: {
      message: "Order deleted successfully"
    }, status: :ok
  end

  private

  def normalize_item(item)
    image_urls =
      item["image_urls"] ||
      item["images"] ||
      []

    image_urls =
      JSON.parse(image_urls) if image_urls.is_a?(String)

    image_urls =
      [image_urls] unless image_urls.is_a?(Array)

    image_urls = image_urls
      .compact
      .map(&:to_s)
      .reject(&:blank?)

    {
      id: item["id"],
      name: item["name"].presence ||
            item["title"].presence ||
            "Product",

      heading: item["heading"].presence ||
               item["name"].presence ||
               "Product",

      image_urls: image_urls,

      image_url: image_urls.first,

      sale_price: item["sale_price"].presence,

      price: item["price"].presence ||
             item["discount_price"].presence ||
             item["mrp"],

      quantity:
        item["quantity"].to_i > 0 ?
        item["quantity"].to_i :
        1
    }

  rescue JSON::ParserError
    normalize_item(
      item.merge(
        "image_urls" => []
      )
    )
  end
end