Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do

      post "send-otp", to: "otp#send_otp"
      post "verify-otp", to: "otp#verify_otp"

      post "payments/create", to: "payments#create"

      match "payments/success",
            to: "payments#success",
            via: [:get, :post]

      match "payments/failure",
            to: "payments#failure",
            via: [:get, :post]

      # USER ORDERS
      get "users/:user_id/orders",
          to: "orders#index"

      # SELLER ORDERS
      get "seller/orders",
          to: "orders#seller_orders"

      patch "seller/orders/:id/status",
            to: "orders#update_status"

      delete "orders/:id",
             to: "orders#destroy"

      patch "users/:id",
            to: "users#update"

      # CONTENTS
      resources :contents, only: [:index]

      get "product-categories",
          to: "contents#product_categories"

      # PRODUCTS
      resources :products,
                only: [:index, :create, :update, :destroy]

      # CATEGORIES
      get "categories",
          to: "categories#index"

      # DEVICE TOKENS
      resources :device_tokens,
                only: [:create]

      # CART
      resources :carts, only: [:show,:update, :create] do
        resources :cart_items,
                  only: [:create, :update, :destroy]
      end

    end
  end
end