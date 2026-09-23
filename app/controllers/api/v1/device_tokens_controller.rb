class Api::V1::DeviceTokensController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.info "================================"
    Rails.logger.info "DEVICE TOKEN CREATE"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "================================"

    token = params[:token]
    user_id = params[:user_id]

    if token.blank?
      render json: {
        success: false,
        message: "FCM token is required"
      }, status: :unprocessable_entity
      return
    end

    if user_id.blank?
      render json: {
        success: false,
        message: "User ID is required"
      }, status: :unprocessable_entity
      return
    end

    device_token = DeviceToken.find_or_initialize_by(
      token: token
    )

    device_token.user_id = user_id

    if device_token.save
      Rails.logger.info "✅ DEVICE TOKEN SAVED"
      Rails.logger.info "Token ID: #{device_token.id}"
      Rails.logger.info "User ID: #{device_token.user_id}"

      render json: {
        success: true,
        message: "Device token saved successfully",
        device_token: {
          id: device_token.id,
          user_id: device_token.user_id
        }
      }, status: :ok
    else
      Rails.logger.error "❌ DEVICE TOKEN SAVE FAILED"
      Rails.logger.error device_token.errors.full_messages

      render json: {
        success: false,
        errors: device_token.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end