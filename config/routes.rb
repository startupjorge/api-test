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

  get "api_calls", to: redirect("/api_queries")
  get "api_queries",                    to: "api_calls#index",             as: :api_queries
  get "api_queries/rank_trends",        to: "api_calls#rank_trends",       as: :api_query_rank_trends
  get "api_queries/not_mentioned",      to: "api_calls#not_mentioned",     as: :api_query_not_mentioned
  get "api_queries/natural_language",   to: "api_calls#natural_language",  as: :api_query_natural_language

  resources :invite, only: [:index]

  resource :settings, only: [:show, :update]

  get "how_to", to: "how_to#index"
  get "how_to/customer", to: "how_to#customer", as: :how_to_customer
  get "how_to/try_it_live", to: "how_to#try_it_live"
end
