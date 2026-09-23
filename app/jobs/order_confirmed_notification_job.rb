class OrderConfirmedNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, order_id)
    user = User.find_by(id: user_id)
    order = Order.find_by(id: order_id)

    return unless user
    return unless order

    device_tokens = DeviceToken
      .where(user_id: user.id)
      .pluck(:token)

    Rails.logger.info(
      " Order notification tokens found: #{device_tokens.count}"
    )

    device_tokens.each do |token|
      FirebaseNotificationService.send_notification(
        token,
        "Order Confirmed",
        "Your order ##{order.id} has been confirmed successfully!"
      )
    end
  end
end