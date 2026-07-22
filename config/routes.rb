Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  namespace :onboarding do
    resource :cv_upload, only: %i[new create]
    resource :status, only: %i[show]
    resource :profile, only: %i[edit update]
  end

  resources :candidates, only: %i[index show] do
    member { get :cv }
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
