Rails.application.routes.draw do
  resources :haikus
  root 'haikus#index'
end
