ActiveAdmin.register User do
  permit_params :phone, :name, :email

  index do
    selectable_column
    id_column

    column :phone
    column :name
    column :email
    column :created_at

    actions
  end

 controller do
  def destroy
    user = User.find(params[:id])

    # Delete user's device tokens
    DeviceToken.where(user_id: user.id).delete_all

    # Delete user's orders
    Order.where(user_id: user.id).delete_all

    # Delete user
    user.destroy!

    redirect_to admin_users_path,
                notice: "User and related orders deleted successfully."
  end
end
end
