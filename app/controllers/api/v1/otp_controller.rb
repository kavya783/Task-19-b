class Api::V1::OtpController < ApplicationController
  skip_before_action :verify_authenticity_token

  def send_otp
    phone = normalize_phone(params[:phone])

    if phone.blank?
      return render json: {
        success: false,
        message: "Phone number is required"
      }, status: :bad_request
    end

    seller = Seller
      .select(:id, :email, :name, :phone)
      .find_by(phone: phone)

    user = User
      .select(:id, :email, :name, :phone)
      .find_by(phone: phone)

    otp = rand(100000..999999).to_s

    Otp.create!(
      phone: phone,
      otp: otp,
      status: "pending",
      expires_at: 5.minutes.from_now
    )

    Rails.logger.info "OTP GENERATED: #{otp}"
    Rails.logger.info "OTP SAVED FOR: #{phone}"

    render json: {
      success: true,
      message: "OTP generated successfully"
    }, status: :ok
  end

  def verify_otp
    phone = normalize_phone(params[:phone])
    entered_otp = params[:otp].to_s

    if phone.blank? || entered_otp.blank?
      return render json: {
        success: false,
        message: "Phone and OTP are required"
      }, status: :bad_request
    end

    otp_record = Otp
      .where(
        phone: phone,
        status: "pending"
      )
      .where("expires_at > ?", Time.current)
      .order(created_at: :desc)
      .first

    unless otp_record
      return render json: {
        success: false,
        message: "OTP not found or expired"
      }, status: :unauthorized
    end

    unless otp_record.otp == entered_otp
      return render json: {
        success: false,
        message: "Invalid OTP"
      }, status: :unauthorized
    end

    # OTP verified successfully
    otp_record.update!(status: "verified")

    # Check existing seller
    seller = Seller
      .select(
        :id,
        :phone,
        :name,
        :email
      )
      .find_by(phone: phone)

    if seller
      return render json: {
        success: true,
        message: "Login successful",
        user: {
          id: seller.id,
          phone: seller.phone,
          name: seller.name,
          email: seller.email,
          role: "seller"
        }
      }, status: :ok
    end

    # Check existing user
    user = User
      .select(
        :id,
        :phone,
        :name,
        :email,
        :role
      )
      .find_by(phone: phone)

    if user
      # Send welcome notification directly
      send_welcome_notification(user)

      return render json: {
        success: true,
        message: "Login successful",
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          email: user.email,
          role: user.role
        }
      }, status: :ok
    end

    # Create new user
    user = User.create!(
      phone: phone
    )

    # Send welcome notification directly
    send_welcome_notification(user)

    render json: {
      success: true,
      message: "Login successful",
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        role: user.role
      }
    }, status: :ok
  end

  private

  def send_welcome_notification(user)
    device_tokens = DeviceToken
      .where(user_id: user.id)
      .pluck(:token)

    Rails.logger.info(
      " Welcome notification tokens found: #{device_tokens.count}"
    )

    if device_tokens.empty?
      Rails.logger.info(
        " No device token found for user: #{user.id}"
      )
      return
    end

    device_tokens.each do |token|
      FirebaseNotificationService.send_notification(
        token,
        "Welcome #{user.name.presence || 'User'}",
        "Welcome to Mamaearth!"
      )
    end

    Rails.logger.info(
      " Welcome notification sent for user: #{user.id}"
    )
  rescue => e
    Rails.logger.error(
      " Welcome notification failed: #{e.class}: #{e.message}"
    )
  end

  def normalize_phone(phone)
    phone.to_s.gsub(/\D/, "").last(10)
  end
end