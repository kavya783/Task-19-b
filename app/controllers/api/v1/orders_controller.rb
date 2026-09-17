class Api::V1::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    orders = Order.where(user_id: params[:user_id]).order(created_at: :desc)

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

  def destroy
    order = Order.find(params[:id])
    order.destroy!

    render json: {
      message: "Order deleted successfully"
    }, status: :ok
  end

  private
  def normalize_item(item)
    image_urls = item["image_urls"] || item["images"] || []
    image_urls = JSON.parse(image_urls) if image_urls.is_a?(String)
    image_urls = [image_urls] unless image_urls.is_a?(Array)
    image_urls = image_urls.compact.map(&:to_s).reject(&:blank?)

    {
      id: item["id"],
      name: item["name"].presence || item["title"].presence || "Product",
      heading: item["heading"].presence || item["name"].presence || "Product",
      image_urls: image_urls,
      image_url: image_urls.first,
      sale_price: item["sale_price"].presence,
      price: item["price"].presence || item["discount_price"].presence || item["mrp"],
      quantity: item["quantity"].to_i > 0 ? item["quantity"].to_i : 1
    }
  rescue JSON::ParserError
    normalize_item(item.merge("image_urls" => []))
  end
end