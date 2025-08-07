BetterRailsSecretsManager::Engine.routes.draw do
  root "secrets#index"
  
  get 'edit', to: 'secrets#edit'
  post 'update', to: 'secrets#update'
  get 'switch_environment', to: 'secrets#switch_environment'
  post 'add_environment', to: 'secrets#add_environment'
  delete 'remove_environment', to: 'secrets#remove_environment'
  post 'export', to: 'secrets#export'
  post 'import', to: 'secrets#import'
  
  resources :sessions, only: [:new, :create, :destroy]
end