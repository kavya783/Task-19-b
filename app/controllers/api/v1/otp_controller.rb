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

    # Welcome push notification after 3 seconds
    WelcomeNotificationJob
      .set(wait: 3.seconds)
      .perform_later(user.id)

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

  # Welcome push notification after 3 seconds
  WelcomeNotificationJob
    .set(wait: 3.seconds)
    .perform_later(user.id)

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

  def normalize_phone(phone)
    phone.to_s.gsub(/\D/, "").last(10)
  end
end