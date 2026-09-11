Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      post "send-otp", to: "otp#send_otp"
      post "verify-otp", to: "otp#verify_otp"

      patch "users/:id", to: "users#update"

      resources :contents, only: [:index]
      get "product-categories", to: "contents#product_categories"
      resources :products, only: [:index, :create, :update, :destroy]
        get "categories", to: "categories#index"
    end
  end
end