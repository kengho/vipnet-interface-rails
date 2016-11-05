Rails.application.routes.draw do
  root "nodes#index"

  # close registration
  resources :users, only: [:update, :edit]
  resources :user_sessions, only: [:create, :destroy]

  delete '/sign_out', to: 'user_sessions#destroy', as: :sign_out
  get '/sign_in', to: 'user_sessions#new', as: :sign_in

  match 'users/:id' => 'users#destroy', :via => :delete
  match 'users/:id' => 'users#update', :via => :get

  resources :nodes, only: [:index]
  get 'nodes/load', to: 'nodes#load'
  get 'nodes/info', to: 'nodes#info'
  get 'nodes/history', to: 'nodes#history'
  get 'nodes/availability', to: 'nodes#availability'

  namespace :api do
    namespace :v1 do
      resources :doc, only: [:index]
      # in
      resources :iplirconfs, only: [:create]
      resources :nodenames, only: [:create]
      resources :tickets, only: [:create]
      # out
      resources :nodes, only: [:index]
      resources :accessips, only: [:index]
      resources :availability, only: [:index]
    end
  end
  resources :settings, only: [:index]
end
