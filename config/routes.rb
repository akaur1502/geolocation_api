Rails.application.routes.draw do
  # Health check (Rails default)
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # query is the IP or URL; allow dots and other URL characters in the id
      resources :locations, only: [ :create, :show, :destroy ], param: :query, constraints: { query: /[^\/]+/ }
    end
  end
end
