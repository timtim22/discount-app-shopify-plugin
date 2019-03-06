Rails.application.routes.draw do
  resources :tickets
  resources :sale_collections
  resources :sales do
  	collection do
  		put 'medit'
  	end
  end
  post '/webhooks/app_uninstalled', to: "shops#uninstall"
  root :to => 'sales#index'
  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
