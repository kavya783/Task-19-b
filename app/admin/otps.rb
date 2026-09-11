ActiveAdmin.register Otp do
  permit_params :phone, :otp, :status, :expires_at

  index do
    selectable_column
    id_column

    column :phone
    column :otp
    column :status
    column :expires_at
    column :created_at

    actions
  end
end