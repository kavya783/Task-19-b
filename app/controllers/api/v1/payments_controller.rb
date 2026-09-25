  class Api::V1::PaymentsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /api/v1/payments/create
def create
  # ============================================================
  # USER VALIDATION
  # ============================================================

  user = User.find_by(id: params[:user_id])

  # User login check
  unless user
    return render json: {
      error: "Please login before making payment"
    }, status: :unauthorized
  end

  # Name and email check
  if user.name.blank? || user.email.blank?
    return render json: {
      error: "Please fill the details"
    }, status: :unprocessable_entity
  end

  # ============================================================
  # PAYMENT DETAILS
  # ============================================================

  txnid = "TXN#{SecureRandom.hex(8)}"

  # Format amount correctly for PayU hash
  amt_float = params[:amount].to_f

  amount =
    if amt_float % 1 == 0
      amt_float.to_i.to_s
    else
      format("%.2f", amt_float)
    end

  productinfo =
    params[:productinfo].to_s.presence ||
    "Mamaearth Order"

  # Use actual logged-in user's details
  firstname = user.name
  email = user.email
  phone = user.phone

  # ============================================================
  # NORMALIZE ITEMS
  # ============================================================

  normalized_items =
    normalize_items(params[:items])

  # ============================================================
  # SAVE ORDER
  # ============================================================

  Order.create!(
    user_id: user.id,
    txnid: txnid,
    amount: amount,
    items: JSON.generate(
      normalized_items
    ),
    status: "pending"
  )

  # ============================================================
  # GENERATE PAYU HASH
  # ============================================================

  hash = PayuService.generate_hash(
    txnid: txnid,
    amount: amount,
    productinfo: productinfo,
    firstname: firstname,
    email: email
  )

  # ============================================================
  # RESPONSE
  # ============================================================

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
  
def success
  Rails.logger.info(
    "PAYU SUCCESS RESPONSE: #{params.to_unsafe_h}"
  )

  order = Order
    .select(
      :id,
      :txnid,
      :status,
      :user_id,
      :amount
    )
    .find_by(
      txnid: params[:txnid]
    )

  if order &&
     params[:status].to_s.downcase == "success"

    order.update!(
      status: "paid"
    )

    Rails.logger.info(
      "ORDER PAYMENT SUCCESSFUL: #{order.id}"
    )

    # SEND ORDER CONFIRMED PUSH NOTIFICATION
    if order.user_id.present?
      OrderConfirmedNotificationJob
        .set(wait: 3.seconds)
        .perform_later(
          order.user_id,
          order.id
        )

      Rails.logger.info(
        "🔔 ORDER CONFIRMATION NOTIFICATION ENQUEUED FOR USER: #{order.user_id}"
      )
    else
      Rails.logger.info(
        "❌ No user associated with order: #{order.id}"
      )
    end
  end

  status = order ? order.status : "paid"

  redirect_to(
    "#{frontend_url}/payment-success?status=#{ERB::Util.url_encode(status)}",
    allow_other_host: true
  )
end

    # GET/POST /api/v1/payments/failure
    def failure
      Rails.logger.info "PAYU FAILURE RESPONSE: #{params.to_unsafe_h}"

      order = Order
        .select(:id)
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