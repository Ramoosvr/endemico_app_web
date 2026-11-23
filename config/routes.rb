Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "login"  => "sessions#new",     as: :login
  post "login"  => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout

  get    "backoffice" => "backoffice#index", as: :backoffice

  get    "usuarios"          => "users#index",   as: :usuarios
  post   "usuarios"          => "users#create"
  get    "usuarios/:id/edit" => "users#edit",    as: :edit_usuario
  patch  "usuarios/:id"      => "users#update",  as: :usuario
  delete "usuarios/:id"      => "users#destroy"

  get "main" => "main#index", as: :main

  get "pedido" => "pedidos#index", as: :pedido

  get  "corte" => "cortes#index", as: :corte
  post "corte/upload" => "cortes#upload_to_drive", as: :corte_upload

  get "google_oauth/authorize" => "google_oauth#authorize", as: :google_oauth_authorize
  get "google_oauth/callback"  => "google_oauth#callback",  as: :google_oauth_callback
  delete "google_oauth"        => "google_oauth#destroy",   as: :google_oauth_disconnect

  get "stock" => "products#index", as: :stock
  resources :products, except: [:index, :new] do
    resources :product_ingredients, only: [:create, :update, :destroy]
    resources :option_groups, only: [:create, :update, :destroy]
  end

  get "insumos" => "ingredients#index", as: :insumos
  resources :ingredients, only: [:index, :create, :edit, :update, :destroy]

  get   "ajustes" => "settings#index", as: :ajustes
  patch "ajustes" => "settings#update"

  get "analisis"                 => "analisis#index",          as: :analisis
  get "analisis/orden-compra"    => "analisis#shopping_list",  as: :analisis_shopping_list, defaults: { format: :csv }
  get "analisis/whatsapp"        => "analisis#whatsapp",       as: :analisis_whatsapp

  get    "agente" => "agent#index",   as: :agente
  post   "agente" => "agent#create"
  delete "agente" => "agent#destroy", as: :agente_reset

  resource :cart, only: [:show] do
    post   "items",         to: "carts#add_item",    as: :items
    patch  "items/:id",     to: "carts#update_item", as: :item
    delete "items/:id",     to: "carts#remove_item"
    post   "checkout",      to: "carts#checkout"
  end

  resource :clip_payment, only: [:create, :show, :destroy], controller: "clip_payments"

  root "main#index"
end
