class Api::V1::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /api/v1/payments/create
  def create
    txnid = "TXN#{SecureRandom.hex(8)}"

    # Format amount correctly for PayU hash
    amt_float = params[:amount].to_f
    amount =
      if amt_float % 1 == 0
        amt_float.to_i.to_s
      else
        format("%.2f", amt_float)
      end

    productinfo = params[:productinfo].to_s.presence || "Mamaearth Order"
    firstname = params[:firstname].to_s.presence || "Customer"
    email = params[:email].to_s.presence || "customer@example.com"
    phone = params[:phone].to_s.presence || "9999999999"

    # Normalize items only once
    normalized_items = normalize_items(params[:items])

    # Save order
    Order.create!(
      user_id: params[:user_id].presence,
      txnid: txnid,
      amount: amount,
      items: JSON.generate(normalized_items),
      status: "pending"
    )

    # Generate PayU security hash
    hash = PayuService.generate_hash(
      txnid: txnid,
      amount: amount,
      productinfo: productinfo,
      firstname: firstname,
      email: email
    )

    render json: {
      key: ENV["PAYU_KEY"],
      txnid: txnid,
      amount: amount,
      productinfo: productinfo,
      firstname: firstname,
      email: email,
      phone: phone,
      surl: "#{backend_url}/api/v1/payments/success",
      furl: "#{backend_url}/api/v1/payments/failure",
      hash: hash
    }, status: :ok
  end

  # GET/POST /api/v1/payments/success
  # GET/POST /api/v1/payments/success
def success
  Rails.logger.info "PAYU SUCCESS RESPONSE: #{params.to_unsafe_h}"

  order = Order
    .select(:id, :txnid, :status)
    .find_by(txnid: params[:txnid])

  if order && params[:status].to_s.downcase == "success"
    order.update!(status: "paid")
  end

  status = order ? order.status : "paid"

  redirect_to(
    "#{frontend_url}/payment-success?status=#{ERB::Util.url_encode(status)}",
    allow_other_host: true
  )
end

  # GET/POST /api/v1/payments/failure
 # GET/POST /api/v1/payments/failure
def failure
  Rails.logger.info "PAYU FAILURE RESPONSE: #{params.to_unsafe_h}"

  order = Order
    .select(:id, :txnid)
    .find_by(txnid: params[:txnid])

  order&.update!(status: "failed")

  redirect_to(
    "#{frontend_url}/payment-failure",
    allow_other_host: true
  )
end

  private

  def backend_url
    ENV.fetch(
      "BACKEND_URL",
      "http://localhost:3000"
    ).chomp("/")
  end

  def frontend_url
    ENV.fetch(
      "FRONTEND_URL",
      "http://localhost:3001"
    ).chomp("/")
  end

  def normalize_items(items)
    Array(items).map do |item|
      item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item.to_h
    end
  end
end