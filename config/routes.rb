Rails.application.routes.draw do
  root "nodes#index"

  # # close registration
  resources :users, only: [:update, :edit]
  # resources :users, only: [:edit]
  # http://stackoverflow.com/questions/5136940/undefined-method-user-path
  # match '/users/:id/edit', :to => 'users#edit', :as => :user, :via => :get
  resources :user_sessions, only: [:create, :destroy]

  delete '/sign_out', to: 'user_sessions#destroy', as: :sign_out
  get '/sign_in', to: 'user_sessions#new', as: :sign_in

  # # close registration
  # get "users/sign_up" => redirect("/404.html")
  # # devise_for :users
  # # https://github.com/plataformatec/devise/wiki/How-To:-Disable-user-from-destroying-their-account
  # devise_for :users, skip: :registrations
  # devise_scope :user do
  #   resource :registration,
  #     only: [:new, :create, :edit, :update],
  #     path: 'users',
  #     path_names: { new: 'sign_up' },
  #     controller: 'devise/registrations',
  #     as: :user_registration do
  #       get :cancel
  #     end
  # end

  match 'users/:id' => 'users#destroy', :via => :delete
  match 'users/:id' => 'users#update', :via => :get

  resources :nodes, only: [:index]
  get 'nodes/availability/:node_id', to: 'nodes#availability'
  get 'nodes/history/:node_id', to: 'nodes#history'

  #api
  namespace :api do
    namespace :v1 do
      resources :doc, only: [:index]
      # data input
      resources :iplirconfs, only: [:create]
      resources :messages, only: [:create]
      resources :nodenames, only: [:create]
      # data output
      resources :nodes, only: [:index]
      resources :accessips, only: [:index]
    end
  end
  resources :settings, only: [:index]
  resources :messages, only: [:index]
  resources :coordinators, only: [:index]
  resources :networks, only: [:index]
  resources :iplirconfs, only: [:index, :show]
end
