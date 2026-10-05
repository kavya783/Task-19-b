ActiveAdmin.register Coupon do
  permit_params :code, :title, :saving, :discount, :minimum_amount, :details, :active

  filter :code
  filter :title
  filter :active
  filter :created_at

  index do
    selectable_column
    id_column
    column :code
    column :title
    column :saving
    column :discount
    column :minimum_amount
    column :active
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :code
      row :title
      row :saving
      row :discount
      row :minimum_amount
      row :details
      row :active
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :code
      f.input :title
      f.input :saving
      f.input :discount
      f.input :minimum_amount
      f.input :details
      f.input :active
    end

    f.actions
  end
end
