require "digest"

class PayuService
  # Generate the request hash before redirecting the user to PayU.
  def self.generate_hash(
    txnid:,
    amount:,
    productinfo:,
    firstname:,
    email:,
    udf1: "",
    udf2: "",
    udf3: "",
    udf4: "",
    udf5: ""
  )
    key = ENV.fetch("PAYU_KEY")
    salt = ENV.fetch("PAYU_SALT")

    hash_string = [
      key,
      txnid,
      amount,
      productinfo,
      firstname,
      email,
      udf1,
      udf2,
      udf3,
      udf4,
      udf5,
      "",
      "",
      "",
      "",
      "",
      salt
    ].join("|")

    Digest::SHA512.hexdigest(hash_string)
  end

  # Verify the hash returned by PayU in the payment callback.
  def self.verify_response_hash(params)
    key = ENV["PAYU_KEY"]
    salt = ENV["PAYU_SALT"]
    received_hash = params[:hash].to_s.downcase

    return false if key.blank? || salt.blank? || received_hash.blank?

    hash_string = [
      salt,
      params[:status].to_s,
      "",
      "",
      "",
      "",
      "",
      params[:udf5].to_s,
      params[:udf4].to_s,
      params[:udf3].to_s,
      params[:udf2].to_s,
      params[:udf1].to_s,
      params[:email].to_s,
      params[:firstname].to_s,
      params[:productinfo].to_s,
      params[:amount].to_s,
      params[:txnid].to_s,
      key
    ].join("|")

    expected_hash = Digest::SHA512.hexdigest(hash_string)

    ActiveSupport::SecurityUtils.secure_compare(
      expected_hash,
      received_hash
    )
  end
end
