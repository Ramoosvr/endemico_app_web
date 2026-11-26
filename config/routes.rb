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

  get "catalogo/:kind" => "catalogo#show", as: :catalogo, constraints: { kind: /bebida|comida|postre/ }

  get "pedido" => "pedidos#index", as: :pedido

  get  "corte" => "cortes#index", as: :corte
  post "corte/upload" => "cortes#upload_to_drive", as: :corte_upload

  get  "pendientes"            => "pendientes#index",            as: :pendientes
  post "pendientes/:id/listo"  => "pendientes#mark_prepared",    as: :pendiente_listo
  post "pendientes/todos"      => "pendientes#mark_all_prepared", as: :pendientes_todos

  get  "pruebas"         => "pruebas#index",   as: :pruebas
  post "pruebas/consume" => "pruebas#consume", as: :pruebas_consume

  get  "devoluciones" => "refunds#index",  as: :devoluciones
  post "devoluciones" => "refunds#create"

  get  "merma" => "mermas#index",  as: :merma
  post "merma" => "mermas#create"

  post "retiro-caja" => "cash_withdrawals#create", as: :cash_withdrawal

  get  "caja"        => "cash_counts#index",  as: :cash_counts
  get  "caja/nueva"  => "cash_counts#new",    as: :new_cash_count
  get  "caja/:id"    => "cash_counts#show",   as: :cash_count
  post "caja"        => "cash_counts#create"

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

  resources :api_tokens, only: [:index, :create, :destroy], path: "api-tokens"

  get "reportes" => "reportes#index", as: :reportes

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
    patch  "name",          to: "carts#set_name",    as: :name
  end

  resource :clip_payment, only: [:create, :show, :destroy], controller: "clip_payments"

  namespace :api do
    namespace :v1 do
      resources :products,    param: :id, only: [:index, :show, :create, :update, :destroy]
      resources :ingredients, param: :id, only: [:index, :show, :create, :update, :destroy]
      resources :sales,       only: [:index]
      get "ventas" => "sales#index"
    end
  end

  root "main#index"
end
