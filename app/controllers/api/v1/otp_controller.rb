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

    # Check whether seller already exists
    seller = Seller
      .select(:id)
      .find_by(phone: phone)

    # Check whether user already exists
    user = User
      .select(:id)
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

    # Find latest pending and non-expired OTP
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

    # Check OTP
    unless otp_record.otp == entered_otp
      return render json: {
        success: false,
        message: "Invalid OTP"
      }, status: :unauthorized
    end

    # Mark OTP as verified
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
        message: "Seller OTP verified successfully",
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
      return render json: {
        success: true,
        message: "User OTP verified successfully",
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

    render json: {
      success: true,
      message: "User created and OTP verified successfully",
      user: {
        id: user.id,
        phone: user.phone,
        role: user.role
      }
    }, status: :ok
  end

  private

  def normalize_phone(phone)
    phone.to_s.gsub(/\D/, "").last(10)
  end
end