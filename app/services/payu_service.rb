require "digest"

class PayuService
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
    key = ENV["PAYU_KEY"]
    salt = ENV["PAYU_SALT"]
Rails.logger.info "PAYU KEY: #{key}"
Rails.logger.info "PAYU SALT LENGTH: #{salt.length}"
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

Rails.logger.info "PAYU HASH: #{Digest::SHA512.hexdigest(hash_string)}"
Rails.logger.info "PAYU KEY LENGTH: #{key.to_s.length}"
Rails.logger.info "PAYU SALT LENGTH: #{salt.to_s.length}"
Digest::SHA512.hexdigest(hash_string)

   
  end
end