Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  get    "logout", to: "sessions#goodbye", as: :logout_page
  delete "logout", to: "sessions#destroy", as: :logout

  root "explore#internal"

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

  get "explore",          to: redirect("/")
  get "explore/internal", to: redirect("/")

  get "api_calls",   to: redirect("/api_runs")
  get "api_queries", to: redirect("/api_runs"), as: :api_queries_redirect
  get "api_runs",                    to: "api_calls#index",             as: :api_queries
  get "api_runs/rank_trends",        to: "api_calls#rank_trends",       as: :api_query_rank_trends
  get "api_runs/not_mentioned",      to: "api_calls#not_mentioned",     as: :api_query_not_mentioned

  resources :invite, only: [:index, :create, :destroy] do
    member do
      patch :update_key
    end
  end

  resource :settings, only: [:show, :update]

  get "how_to", to: "how_to#index"
  get "how_to/customer", to: "how_to#customer", as: :how_to_customer
  get "how_to/try_it_live", to: "how_to#try_it_live"
end
