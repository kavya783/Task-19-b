class AddFirstLoginAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_login_at, :datetime
  end
end
