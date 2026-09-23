class Api::V1::DeviceTokensController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    device_token = DeviceToken.find_or_initialize_by(
      token: params[:token]
    )

    device_token.user_id = params[:user_id]

    if device_token.save
      render json: {
        success: true,
        message: "Device token saved successfully",
        device_token: {
          id: device_token.id,
          user_id: device_token.user_id
        }
      }, status: :ok
    else
      render json: {
        success: false,
        errors: device_token.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end