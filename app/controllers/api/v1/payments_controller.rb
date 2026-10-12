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

  begin
    mama_cash_used = BigDecimal(params[:mama_cash_used].presence || "0")
  rescue ArgumentError, TypeError
    return render json: {
      error: "Invalid MamaCash amount"
    }, status: :unprocessable_entity
  end

  unless mama_cash_used.finite? && mama_cash_used >= 0
    return render json: {
      error: "Invalid MamaCash amount"
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
  # SAVE ORDER
  # ============================================================

  order = nil

  user.with_lock do
    available_balance =
      MamaCashTransaction.available_balance_for(user.id)

    if mama_cash_used > available_balance
      return render json: {
        error: "Insufficient MamaCash balance"
      }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      order = Order.create!(
        user_id: user.id,
        txnid: txnid,
        amount: amount,
        items: JSON.generate(
          normalized_items
        ),
        status: "pending"
      )

      if mama_cash_used.positive?
        MamaCashTransaction.create!(
          user_id: user.id,
          order_id: order.id,
          transaction_type: "redeemed",
          amount: mama_cash_used,
          status: "pending"
        )
      end
    end
  end

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
  order = Order.find_by(txnid: params[:txnid])

  unless order
    Rails.logger.warn("PayU callback received for unknown transaction")
    return redirect_to(
      "#{frontend_url}/payment-failure",
      allow_other_host: true
    )
  end

  # Verify PayU callback hash before trusting its status.
  unless PayuService.verify_response_hash(params)
    Rails.logger.warn("PayU callback hash verification failed")
    return redirect_to(
      "#{frontend_url}/payment-failure",
      allow_other_host: true
    )
  end

  # Ensure the callback amount matches the saved order amount.
  callback_amount = BigDecimal(params[:amount].to_s)
  order_amount = BigDecimal(order.amount.to_s)

  unless callback_amount == order_amount
    Rails.logger.warn("PayU callback amount mismatch for order #{order.id}")
    return redirect_to(
      "#{frontend_url}/payment-failure",
      allow_other_host: true
    )
  end

  unless params[:status].to_s.downcase == "success"
    return redirect_to(
      "#{frontend_url}/payment-failure",
      allow_other_host: true
    )
  end

  reward_amount = (order_amount * BigDecimal("0.10")).round(2)

  begin
    order.with_lock do
      # Prevent duplicate rewards if PayU calls this endpoint again.
      unless order.status == "paid"
        ActiveRecord::Base.transaction do
          order.update!(status: "paid")
          MamaCashTransaction.where(
            order_id: order.id,
            transaction_type: "redeemed",
            status: "pending"
          ).update_all(status: "completed", updated_at: Time.current)

          if order.user_id.present? && reward_amount.positive?
            MamaCashTransaction.create!(
              user_id: order.user_id,
              order_id: order.id,
              transaction_type: "earned",
              amount: reward_amount,
              status: "completed"
            )
          end
        end
      end
    end

    if order.user_id.present?
      OrderConfirmedNotificationJob
        .set(wait: 3.seconds)
        .perform_later(order.user_id, order.id)
    end

    redirect_to(
      "#{frontend_url}/payment-success?status=paid",
      allow_other_host: true
    )
  rescue ActiveRecord::RecordNotUnique
    # The unique earned-per-order index prevents duplicate rewards.
    Rails.logger.info("MamaCash reward already exists for order #{order.id}")

    redirect_to(
      "#{frontend_url}/payment-success?status=paid",
      allow_other_host: true
    )
  rescue StandardError => error
    Rails.logger.error(
      "Payment callback processing failed for order #{order.id}: #{error.class}"
    )

    redirect_to(
      "#{frontend_url}/payment-failure",
      allow_other_host: true
    )
  end
end


    # GET/POST /api/v1/payments/failure
    def failure
      Rails.logger.info "PAYU FAILURE RESPONSE: #{params.to_unsafe_h}"

      order = Order.find_by(txnid: params[:txnid])

      if order&.status == "pending"
        order.with_lock do
          if order.status == "pending"
            order.update!(status: "failed")
            MamaCashTransaction.where(
              order_id: order.id,
              transaction_type: "redeemed",
              status: "pending"
            ).update_all(status: "failed", updated_at: Time.current)
          end
        end
      end

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