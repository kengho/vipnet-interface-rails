Rails.application.routes.draw do
  root "nodes#index"

  resources :users, only: [:update, :edit]
  resources :user_sessions, only: [:create, :destroy]

  get "sign_in", to: "user_sessions#new", as: :sign_in
  delete "sign_out", to: "user_sessions#destroy", as: :sign_out
  get "reset_password", to: "reset_password#index"

  match "users/:id" => "users#update", via: :get
  match "users/:id" => "users#destroy", via: :delete

  match "settings" => "settings#index", via: :get
  match "settings" => "settings#update", via: :patch

  get "nodes",              to: "nodes#index"
  get "nodes/load",         to: "nodes#load"
  get "nodes/info",         to: "nodes#info"
  get "nodes/history",      to: "nodes#history"
  get "nodes/availability", to: "nodes#availability"

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
end
