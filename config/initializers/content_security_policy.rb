# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    policy.font_src :self,
                    :https,
                    :data

    policy.img_src :self,
                   :https,
                   :data

    policy.object_src :none

    policy.script_src :self,
                      :https

    policy.style_src :self,
                     :https,
                     :unsafe_inline

    policy.connect_src :self,
                      :https

    policy.frame_src :self,
                     :https

    policy.frame_ancestors :self

    policy.base_uri :self

    policy.form_action :self,
                       :https

    # Trusted Types
    policy.require_trusted_types_for :script
  end
end