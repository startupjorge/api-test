Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  root "explore#internal"

  resources :reports, only: [ :index, :show ] do
    member do
      get :trends
      get :customer_trends
    end
    resources :runs, only: [ :index, :show ], controller: "report_runs", param: :ordinal do
      member do
        get "raw"
        get "not_mentioned"
        get "customer_not_mentioned"
      end
    end
  end

  get "explore",          to: redirect("/explore/internal")
  get "explore/internal", to: "explore#internal", as: :explore_internal
  get "explore/customer", to: "explore#customer", as: :explore_customer

  get  "api_calls", to: "api_calls#index", as: :api_calls

  resources :invite, only: [:index, :create, :destroy]

  resource :settings, only: [:show, :update]

  get "how_to", to: "how_to#index"
  get "how_to/customer", to: "how_to#customer", as: :how_to_customer
  get "how_to/try_it_live", to: "how_to#try_it_live"
end
