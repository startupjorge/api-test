Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  get  "logout", to: "sessions#destroy", as: :logout

  get "access/:token", to: "sessions#access", as: :access_link

  root "reports#index"

  resources :reports, only: [ :index, :show ] do
    member do
      get :trends
    end
    resources :runs, only: [ :index, :show ], controller: "report_runs", param: :ordinal do
      member do
        get "raw"
        get "not_mentioned"
      end
    end
  end

  resources :invite, only: [:index, :create]

  resource :settings, only: [:show, :update]

  resources :custom_queries
end
