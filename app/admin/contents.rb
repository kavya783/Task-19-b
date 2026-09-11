ActiveAdmin.register Content do
  permit_params :category,
                :subcategory,
                :heading,
                :image_url,
                :subheading,
                :description

  filter :category
  filter :subcategory
  filter :heading
  filter :subheading
  filter :description
  filter :created_at

  index do
    selectable_column
    id_column

    column :category
    column :subcategory
    column :heading

    column "Image" do |content|
      if content.image_url.present?
        image_tag(
          content.image_url,
          style: "width: 100%; height: 60px; object-fit: contain; display: block;"
        )
      else
        "No Image"
      end
    end

    column :subheading
    column :description
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :category
      row :subcategory
      row :heading

      row "Image" do |content|
        if content.image_url.present?
          image_tag(
            content.image_url,
            style: "max-width: 100%; height: auto; display: block;"
          )
        else
          "No Image"
        end
      end

      row :subheading
      row :description
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :category
      f.input :subcategory
      f.input :heading

      f.input :image_url,
              label: "Image URL"

      f.input :subheading
      f.input :description
    end

    f.actions
  end
end