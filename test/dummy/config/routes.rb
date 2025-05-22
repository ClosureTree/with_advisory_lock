# frozen_string_literal: true

Rails.application.routes.draw do
  resources :tsa, only: %i[index show destroy] do
    member do
      post :set
      post :append
      delete :remove
    end
  end
end
