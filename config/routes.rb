Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :mortgage_applications, only: [:create, :show] do
        resources :assessments, only: [:create, :show]
      end
    end
  end
end
