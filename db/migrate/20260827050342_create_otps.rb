class CreateOtps < ActiveRecord::Migration[8.1]
  def change
    create_table :otps do |t|
      t.string :phone
      t.string :otp
      t.string :status
      t.datetime :expires_at

      t.timestamps
    end
  end
end
