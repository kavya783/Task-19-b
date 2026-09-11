class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token

 def update
  user = User.find(params[:id])

  puts "========== PROFILE UPDATE =========="
  puts "PARAMS: #{params.inspect}"
  puts "NAME FROM PARAMS: #{params[:user][:name]}"
  puts "EMAIL FROM PARAMS: #{params[:user][:email]}"

  if user.update(user_params)
    puts "UPDATED NAME: #{user.name}"

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