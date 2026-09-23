class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_tokens do |t|
      t.string :token, null: false
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
  end
end