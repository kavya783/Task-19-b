Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      post "send-otp", to: "otp#send_otp"
      post "verify-otp", to: "otp#verify_otp"
      
        post "payments/create", to: "payments#create"
        match "payments/success", to: "payments#success", via: [:get, :post]
        match "payments/failure", to: "payments#failure", via: [:get, :post]
        get "users/:user_id/orders", to: "orders#index"
         delete "orders/:id", to: "orders#destroy"
      patch "users/:id", to: "users#update"

      resources :contents, only: [:index]
      get "product-categories", to: "contents#product_categories"
      resources :products, only: [:index, :create, :update, :destroy]
        get "categories", to: "categories#index"
         resources :device_tokens, only: [:create]

    end
  end
end