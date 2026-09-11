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
end