class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token

  # PATCH /api/v1/users/:id
  def update
    user = User
      .select(:id, :name, :email, :phone, :role)
      .find(params[:id])

    if user.update(user_params)
      render json: {
        success: true,
        message: "Profile updated successfully",
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role
        }
      }, status: :ok
    else
      render json: {
        success: false,
        message: "Profile update failed",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end