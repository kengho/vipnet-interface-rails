Rails.application.routes.draw do
  root "nodes#index"

  # # close registration
  resources :users, only: [:update, :edit]
  # http://stackoverflow.com/questions/5136940/undefined-method-user-path
  # match '/users/:id/edit', :to => 'users#edit', :as => :user, :via => :get
  resources :user_sessions, only: [:create, :destroy]

  delete '/sign_out', to: 'user_sessions#destroy', as: :sign_out
  get '/sign_in', to: 'user_sessions#new', as: :sign_in

  match 'users/:id' => 'users#destroy', :via => :delete
  match 'users/:id' => 'users#update', :via => :get

  resources :nodes, only: [:index]
  get 'nodes/availability/:node_id', to: 'nodes#availability'
  get 'nodes/history/:node_id', to: 'nodes#history'
  get 'nodes/info/:node_id', to: 'nodes#info'

  #api
  namespace :api do
    namespace :v1 do
      resources :doc, only: [:index]
      # data input
      resources :iplirconfs, only: [:create]
      resources :nodenames, only: [:create]
      resources :tickets, only: [:create]
      # data output
      resources :nodes, only: [:index]
      resources :accessips, only: [:index]
      resources :availability, only: [:index]
    end
  end
  resources :settings, only: [:index]
  resources :coordinators, only: [:index]
  resources :networks, only: [:index]
  resources :iplirconfs, only: [:index, :show]
end
