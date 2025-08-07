BetterRailsSecretsManager::Engine.routes.draw do
  root "secrets#index"
  
  resources :secrets, only: [:index] do
    collection do
      get :edit
      post :update
      get :switch_environment
      post :add_environment
      delete :remove_environment
      post :export
      post :import
    end
  end
  
  resources :sessions, only: [:new, :create, :destroy]
end