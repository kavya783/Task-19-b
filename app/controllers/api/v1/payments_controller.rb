class Api::V1::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    txnid = "TXN#{SecureRandom.hex(8)}"

    # FIX: Ensure clean handling of amount formatting to prevent hash mismatches
    amt_float = params[:amount].to_f
    amount = (amt_float % 1 == 0) ? amt_float.to_i.to_s : format("%.2f", amt_float)

    productinfo = params[:productinfo].to_s.presence || "Mamaearth Order"
    firstname = params[:firstname].to_s.presence || "Customer"
    email = params[:email].to_s.presence || "customer@example.com"
    phone = params[:phone].to_s.presence || "9999999999"

    # Save to database
    Order.create!(
      user_id: params[:user_id].presence,
      txnid: txnid,
      amount: amount,
      items: JSON.generate(normalize_items(params[:items])),
      status: "pending"
    )

    # Generate the security hash
    hash = PayuService.generate_hash(
      txnid: txnid,
      amount: amount,
      productinfo: productinfo,
      firstname: firstname,
      email: email
    )

    # Return the clean payload to the frontend
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
    }
  end

  def success
  Rails.logger.info "PAYU SUCCESS RESPONSE: #{params.to_unsafe_h}"

  order = Order.find_by(txnid: params[:txnid])

  if order && params[:status].to_s.downcase == "success"
    order.update!(status: "paid")
  end

  redirect_to(
    "#{frontend_url}/payment-success?status=#{ERB::Util.url_encode(order ? order.status : 'paid')}",
    allow_other_host: true
  )
end

  def failure
    Rails.logger.info "PAYU FAILURE RESPONSE: #{params.to_unsafe_h}"
    Order.find_by(txnid: params[:txnid])&.update!(status: "failed")
 redirect_to "#{frontend_url}/payment-failure", allow_other_host: true
  end

  private

  def backend_url
    ENV.fetch("BACKEND_URL", "http://localhost:3000").chomp("/")
  end

  def frontend_url
    ENV.fetch("FRONTEND_URL", "http://localhost:3001").chomp("/")
  end

  def normalize_items(items)
    Array(items).map do |item|
      item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item.to_h
    end
  end
end
