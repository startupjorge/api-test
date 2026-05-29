Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  root "reports#index"

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

  get "explore",           to: redirect("/explore/internal")
  get "explore/internal",  to: "explore#internal",  as: :explore_internal
  get "explore/customer",  to: "explore#customer",  as: :explore_customer

  get "how_to", to: "how_to#index"
  get "how_to/customer", to: "how_to#customer", as: :how_to_customer
  get "how_to/try_it_live", to: "how_to#try_it_live"

  resource :settings, only: [:show, :update] do
    get :customer
  end
end
