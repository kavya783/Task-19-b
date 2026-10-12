
class Api::V1::PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /api/v1/payments/create
  def create
    user = User.find_by(id: params[:user_id])

    unless user
      return render json: {
        success: false,
        error: "Please login before making payment"
      }, status: :unauthorized
    end

    if user.name.blank? || user.email.blank?
      return render json: {
        success: false,
        error: "Please fill the details"
      }, status: :unprocessable_entity
    end

    begin
      payable_amount = BigDecimal(params[:amount].to_s)
      mama_cash_used = BigDecimal(
        params[:mama_cash_used].presence || "0"
      )
    rescue ArgumentError, TypeError
      return render json: {
        success: false,
        error: "Invalid payment amount"
      }, status: :unprocessable_entity
    end

    unless payable_amount.finite? &&
           payable_amount > 0 &&
           mama_cash_used.finite? &&
           mama_cash_used >= 0
      return render json: {
        success: false,
        error: "Invalid payment or MamaCash amount"
      }, status: :unprocessable_entity
    end

    txnid = "TXN#{SecureRandom.hex(8)}"

    amount = format("%.2f", payable_amount)

    productinfo =
      params[:productinfo].to_s.presence || "Mamaearth Order"

    normalized_items = normalize_items(params[:items])

    firstname = user.name
    email = user.email
    phone = user.phone

    order = nil

    user.with_lock do
      available_balance =
        MamaCashTransaction.available_balance_for(user.id)

      if mama_cash_used > available_balance
        return render json: {
          success: false,
          error: "Insufficient MamaCash balance"
        }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        order = Order.create!(
          user_id: user.id,
          txnid: txnid,
          amount: amount,
          mama_cash_used: mama_cash_used,
          items: JSON.generate(normalized_items),
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

    payment_hash = PayuService.generate_hash(
      txnid: txnid,
      amount: amount,
      productinfo: productinfo,
      firstname: firstname,
      email: email
    )

    render json: {
      success: true,
      key: ENV["PAYU_KEY"],
      txnid: txnid,
      amount: amount,
      productinfo: productinfo,
      firstname: firstname,
      email: email,
      phone: phone,
      surl: "#{backend_url}/api/v1/payments/success",
      furl: "#{backend_url}/api/v1/payments/failure",
      hash: payment_hash
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error(
      "Payment order creation failed: #{error.class}"
    )

    render json: {
      success: false,
      error: "Unable to create payment order"
    }, status: :unprocessable_entity
  end

  # GET/POST /api/v1/payments/success
  def success
    order = Order.find_by(txnid: params[:txnid])

    unless order
      Rails.logger.warn("PayU success callback: unknown transaction")

      return redirect_to(
        "#{frontend_url}/payment-failure",
        allow_other_host: true
      )
    end

    unless PayuService.verify_response_hash(params)
      Rails.logger.warn(
        "PayU callback hash verification failed for order #{order.id}"
      )

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

    begin
      callback_amount = BigDecimal(params[:amount].to_s)
      order_amount = BigDecimal(order.amount.to_s)
    rescue ArgumentError, TypeError
      return redirect_to(
        "#{frontend_url}/payment-failure",
        allow_other_host: true
      )
    end

    unless callback_amount == order_amount
      Rails.logger.warn(
        "PayU amount mismatch for order #{order.id}"
      )

      return redirect_to(
        "#{frontend_url}/payment-failure",
        allow_other_host: true
      )
    end

    begin
      order.with_lock do
        # A previously completed order must not earn MamaCash again.
        if order.status != "paid"
          ActiveRecord::Base.transaction do
            order.update!(status: "paid")

            # Deduct redeemed MamaCash only after successful payment.
            MamaCashTransaction.where(
              order_id: order.id,
              transaction_type: "redeemed",
              status: "pending"
            ).update_all(
              status: "completed",
              updated_at: Time.current
            )

            if order.user_id.present?
              mama_cash_used = BigDecimal(
                order.mama_cash_used.to_s
              )

              # Reward on the eligible purchase total before MamaCash
              # redemption. Adjust this base if your reward policy
              # excludes discounts, shipping, or other charges.
              reward_base = order_amount + mama_cash_used

              reward_amount = (
                reward_base * BigDecimal("0.10")
              ).round(2)

              if reward_amount.positive?
                existing_reward = MamaCashTransaction.exists?(
                  order_id: order.id,
                  transaction_type: "earned"
                )

                unless existing_reward
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
    rescue StandardError => error
      Rails.logger.error(
        "Payment callback failed for order #{order.id}: " \
        "#{error.class}: #{error.message}"
      )

      redirect_to(
        "#{frontend_url}/payment-failure",
        allow_other_host: true
      )
    end
  end

  # GET/POST /api/v1/payments/failure
  def failure
    order = Order.find_by(txnid: params[:txnid])

    if order&.status == "pending"
      order.with_lock do
        if order.status == "pending"
          ActiveRecord::Base.transaction do
            order.update!(status: "failed")

            MamaCashTransaction.where(
              order_id: order.id,
              transaction_type: "redeemed",
              status: "pending"
            ).update_all(
              status: "failed",
              updated_at: Time.current
            )
          end
        end
      end
    end

    redirect_to(
      "#{frontend_url}/payment-failure",
      allow_other_host: true
    )
  rescue StandardError => error
    Rails.logger.error(
      "Payment failure callback error: #{error.class}"
    )

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
      if item.respond_to?(:to_unsafe_h)
        item.to_unsafe_h
      elsif item.respond_to?(:to_h)
        item.to_h
      else
        {}
      end
    end
  end
end
