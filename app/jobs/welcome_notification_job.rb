class WelcomeNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    name = user.name.presence || "User"

    device_tokens = DeviceToken.where(
      user_id: user.id
    ).pluck(:token)

    puts "Device tokens found: #{device_tokens.count}"

    device_tokens.each do |token|
      FirebaseNotificationService.send_notification(
        token,
        "Welcome #{name}",
        "Welcome to Mamaearth!"
      )
    end
  end
end