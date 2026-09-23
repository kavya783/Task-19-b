
require "googleauth"
require "net/http"
require "json"

class FirebaseNotificationService

  def self.send_notification(device_token, title, body)

    project_id = ENV["FIREBASE_PROJECT_ID"]

    scope = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ]

    key_path =
      if Rails.env.production?
        "/etc/secrets/serviceAccountKey.json"
      else
        Rails.root.join(
          "config",
          "serviceAccountKey.json"
        )
      end

    authorizer =
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(key_path),
        scope: scope
      )

    authorizer.fetch_access_token!

    access_token = authorizer.access_token

    uri = URI(
      "https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send"
    )

    http = Net::HTTP.new(
      uri.host,
      uri.port
    )

    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)

    request["Authorization"] =
      "Bearer #{access_token}"

    request["Content-Type"] =
      "application/json"

    request.body = {
      message: {
        token: device_token,

        notification: {
          title: title,
          body: body
        }
      }
    }.to_json

    response = http.request(request)

    if response.code.to_i == 200

      Rails.logger.info(
        "✅ Mamaearth notification sent successfully"
      )

      Rails.logger.info(
        "Firebase response: #{response.body}"
      )

    else

      Rails.logger.error(
        "❌ Mamaearth notification failed"
      )

      Rails.logger.error(
        "Firebase response: #{response.body}"
      )

    end

    response

  end

end
    