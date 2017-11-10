Rails.application.routes.draw do
  #get 'user/login'

  resources :articles do
    resources :comments
  end

  resources :users
  resources :sessions

  post "/" => "sessions#require_login"
  get "/logout" => "sessions#logout"

  root 'users#login'
end
