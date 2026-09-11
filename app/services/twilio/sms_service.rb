require "twilio-ruby"

module Twilio
  class SmsService
    TWILIO_ACCOUNT_SID = ENV["TWILIO_ACCOUNT_SID"]
    TWILIO_AUTH_TOKEN = ENV["TWILIO_AUTH_TOKEN"]
    TWILIO_FROM_PHONE = ENV["TWILIO_FROM_PHONE"]
    VERIFY_SERVICE_SID = ENV["TWILIO_VERIFY_SERVICE_SID"]
     TWILIO_TEST_PHONE =ENV["TWILIO_TEST_PHONE"]
    def initialize(body: nil, to_phone_number:)
      @body = body
      @to_phone_number = to_phone_number

      @client = Twilio::REST::Client.new(
        TWILIO_ACCOUNT_SID,
        TWILIO_AUTH_TOKEN
      )
    end

    # Normal SMS
    def call
      return false if @body.blank? || @to_phone_number.blank?

      message = @client.messages.create(
        body: @body,
        from: TWILIO_FROM_PHONE,
        to: TWILIO_TEST_PHONE
      )

      Rails.logger.info "SMS Sent! SID: #{message.sid}"
      true
    rescue Twilio::REST::TwilioError => e
      Rails.logger.error "Twilio SMS Error: #{e.message}"
      false
    end

    # Send OTP using Twilio Verify
    def send_otp
      return false if @to_phone_number.blank?

      verification = @client
                           .verify
                           .v2
                           .services(VERIFY_SERVICE_SID)
                           .verifications
                           .create(
                             to: @to_phone_number,
                             channel: "sms"
                           )

      Rails.logger.info "Twilio Verify OTP Status: #{verification.status}"
      true
    rescue Twilio::REST::TwilioError => e
      Rails.logger.error "Twilio Verify Error: #{e.message}"
      false
    end

    # Verify OTP
    def check_otp(code)
      return false if code.blank? || @to_phone_number.blank?

      verification_check = @client
                                  .verify
                                  .v2
                                  .services(VERIFY_SERVICE_SID)
                                  .verification_checks
                                  .create(
                                    to: @to_phone_number,
                                    code: code
                                  )

      Rails.logger.info(
        "Twilio Verification Status: #{verification_check.status}"
      )

      verification_check.status == "approved"
    rescue Twilio::REST::TwilioError => e
      Rails.logger.error "Twilio Verification Check Error: #{e.message}"
      false
    end
  end
end